class PerformanceMeasure < ActiveRecord::Base

  # ----------------------- Associations --------------------

  belongs_to :measurable, polymorphic: true

  belongs_to :key_focus_area, -> { where(performance_measures: { measurable_type: :KeyFocusArea }) }, foreign_key: 'measurable_id'
  belongs_to :objective, -> { where(performance_measures: { measurable_type: :Objective }) }, foreign_key: 'measurable_id'

  belongs_to :author, foreign_key: :created_by_user_id, class_name: "User"
  belongs_to :last_editor, foreign_key: :last_updated_by_user_id, class_name: "User"

  has_many :measure_reports, dependent: :destroy
  has_many :performance_factors, dependent: :destroy

  accepts_nested_attributes_for :performance_factors,
                                reject_if: :all_blank,
                                allow_destroy: true

  # ----------------------- Validations --------------------

  validates :measurable_id, :measurable_type, :description, :unit_of_measure, :created_by_user_id,
            presence: true
  
  # ----------------------- Virtual attributes --------------------

  def kfa_name
    return measurable.name if measurable_type == "KeyFocusArea"
    measurable.key_focus_area.name
  end

  def self.kfas
    joins("INNER JOIN key_focus_areas ON key_focus_areas.id = performance_measures.measurable_id AND performance_measures.measurable_type = 'KeyFocusArea'")
  end

  def self.objectives
    joins("INNER JOIN objectives ON objectives.id = performance_measures.measurable_id AND performance_measures.measurable_type = 'Objective'").
    joins("INNER JOIN key_focus_areas ON objectives.key_focus_area_id = key_focus_areas.id")
  end

  def self.all_with_kfa
    joins(" INNER JOIN key_focus_areas ON key_focus_areas.id = performance_measures.measurable_id AND performance_measures.measurable_type = 'KeyFocusArea'
            UNION 
            SELECT performance_measures.* FROM performance_measures
            INNER JOIN objectives ON objectives.id = performance_measures.measurable_id AND performance_measures.measurable_type = 'Objective'
            INNER JOIN key_focus_areas ON objectives.key_focus_area_id = key_focus_areas.id").
    order("key_focus_areas.name ASC, objectives.name ASC")
  end

  def parents
    # Display N/A in objectives for those measures that target directly a KFA
    dummy = OpenStruct.new( { name: "N/A", model_name: OpenStruct.new({ human: "Objective" }) })
    return [measurable, dummy] if measurable_type == "KeyFocusArea"
    [measurable.key_focus_area, measurable]
  end

end
