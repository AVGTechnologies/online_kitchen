# == Schema Information
#
# Table name: configurations
#
#  id         :integer          not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Configuration < ActiveRecord::Base
  has_many :machines, dependent: :destroy, inverse_of: :configuration
  belongs_to :user

  validates :name, presence: true, uniqueness: true, length: {minimum: 3}

  strip_attributes

  def as_json(options = {})
    #TODO: set only proper attributes
    #see http://jonathanjulian.com/2010/04/rails-to_json-or-as_json/
    super(:include => [:machines])
  end

  def state
    states = machines.pluck(:state).uniq

    case states
      when ['ready']
        'ready'
      when ['destroy_queued']
        'destroy_queued'
      else
        'updating'
    end
  end

  def destroy
    destroyable? ? super : self
  end

  def schedule_destroy
    nested_result = machines.
      where('machines.state <> ?', :destroy_queued).
      map(&:schedule_destroy).
      any?

    nested_result ?  update_attributes(deleted: true) : false
  end


  def machine_attributes
    machines.to_json
  end


  def machine_attributes=(attributes_collection)
    attributes_collection.each do |attributes|
      if attributes['id'].blank?
        #new machine
      elsif existing_record = machines.detect { |record| record.id.to_s == attributes['id'].to_s }
        #update machine
        if attributes['_destroy']
        else
          raise 'TODO: cannot update attributes' #TODO
        end
      else
        raise "TODO", #TODO
      end
    end
  end

  private

    def destroyable?
      return true if machines.count == 0
      errors.add(:base, "Cannot delete configuration with living machines")
      false
    end
end
