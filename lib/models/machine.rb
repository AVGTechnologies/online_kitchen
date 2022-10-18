# == Schema Information
#
# Table name: machines
#
#  id               :integer          not null, primary key
#  name             :string
#  image            :string
#  state            :string           default("queued")
#  ip               :string
#  provider_id      :string
#  environment      :text
#  configuration_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  cluster          :string
#

# Machine representation
class Machine < ActiveRecord::Base
  belongs_to :configuration, inverse_of: :machines

  validates :name,
            presence: true,
            length: { minimum: 3 },
            format: {
              with: %r{\A[A-Za-z0-9_\. ()#\-<>:\|\\\[\]\/]+\z},
              message: 'only allows alphanumeric, brackets and some more special characters'
            }

  validates :state, inclusion: { in: %w[queued deployed ready destroy_queued deleted failed] }
  validates :provider_id, presence: true, if:  ->(s) { s.state == 'ready' }
  validate :environment_has_allowed_structure
  validate :image_is_valid

  after_commit :schedule_provision_vm, on: :create

  serialize :environment, JSON

  strip_attributes except: :environment

  delegate :user, :folder_name, to: :configuration

  scope :queued_older_than, (lambda do |time|
    where(state: 'queued').where('updated_at < ?', time)
  end)

  scope :destroy_queued_older_than, (lambda do |time|
    where(state: 'destroy_queued').where('updated_at < ?', time)
  end)

  scope :deleted_older_than, (lambda do |time|
    where(state: 'deleted').where('updated_at < ?', time)
  end)

  scope :destroy_queued_machines_without_provider_id, (lambda do |time|
    where(state: 'destroy_queued')
      .where('(provider_id IS NULL) OR (provider_id = ?)', '')
      .where('updated_at < ?', time)
  end)

  scope :destroy_queued_machines_without_provider_id, (lambda do |time|
    where(state: 'destroy_queued').where('updated_at < ?', time)
  end)

  def as_json(options = {})
    h = super(options)
    h['template'] = template
    h
  end

  def template
    "#{cluster}.#{image}"
  end

  def template=(value)
    parsed_cluster, parsed_image = value.split('.', 2)
    self.cluster = parsed_cluster
    self.image = parsed_image
  end

  def job_id
    "#{configuration.id}.#{id}"
  end

  def deleted?
    state == 'deleted'
  end

  def destroy_queued?
    state == 'destroy_queued'
  end

  def deleted_or_destroy_queued?
    deleted? || destroy_queued?
  end

  def destroy
    if deleted?
      # VM is not running therefore I can delete AR object
      OnlineKitchen.logger.info "Destroying machine: #{id}"
      super
    elsif state == 'destroy_queued'
      OnlineKitchen.logger.info "Machine: #{id} is already scheduled to destroy."
    else
      OnlineKitchen.logger.info "Scheduling releasing for machine: #{id}"
      self.state = 'destroy_queued'
      save
      run_callbacks :destroy
      3.times.each do |try_n|
        OnlineKitchen::LabManagerRelease.perform_async(id)
        break
      rescue Errno::ETIMEDOUT
        OnlineKitchen.logger.warn("problem with scheduling deletion of machine: #{id}, try: #{try_n}")
      end
      freeze
    end
  end

  def schedule_destroy
    OnlineKitchen.logger.info "Scheduling releasing for machine: #{id}"
    3.times.each do |try_n|
      OnlineKitchen::LabManagerRelease.perform_async(id)
      break
    rescue Errno::ETIMEDOUT
      OnlineKitchen.logger.warn("problem with scheduling deletion of machine: #{id}, try: #{try_n}")
    end
    update_attributes(state: :destroy_queued)
  end

  private

  def schedule_provision_vm
    OnlineKitchen.logger.info "Scheduling provision for machine: #{id}"
    3.times.each do |try_n|
      OnlineKitchen::LabManagerDeploy.perform_async('machine_id' => id, 'deployed' => false)
      OnlineKitchen.logger.info "Provision schedulled for machine: #{id}"
      break
    rescue Errno::ETIMEDOUT
      OnlineKitchen.logger.warn("problem with provision scheduling of machine: #{id}, try: #{try_n}")
    end
  end

  def environment_has_allowed_structure
    return if environment.nil?

    unless environment.is_a?(Hash)
      errors.add(:environment, 'has to be Hash (key-value) like structure')
      return false
    end

    environment.each do |key, value|
      unless key =~ /\A[A-Za-z][A-Za-z0-9_]*\z/
        errors.add(:environment,
                   'keys has to be Literal ' \
                   '(e.g. start on letter followed by letter, digits or underscore)')
        return false
      end
      unless value.is_a?(String)
        errors.add(:environment, 'value has to be String')
        return false
      end
    end
    true
  end

  def image_is_valid
    unless ProviderTemplate.include_image?(image)
      errors.add(:image, 'passed image is not supported')
    end
  end
end
