class MeasureReport < ActiveRecord::Base

  # ----------------------- Associations --------------------

  belongs_to :performance_measure

  belongs_to  :author, 
              foreign_key: :created_by_user_id, 
              class_name: "User"
  
  belongs_to  :last_editor, 
              foreign_key: :last_updated_by_user_id, 
              class_name: "User"

  has_many  :performance_factor_entries, 
            dependent: :destroy
  
  has_many  :performance_factors, 
            through: :performance_factor_entries
  
  has_many  :form_factors, 
            through: :performance_measure, 
            source: :performance_factors

  # ----------------------- Nested Form --------------------
  
  accepts_nested_attributes_for :performance_factor_entries,
                                reject_if: :all_blank,
                                allow_destroy: true

  # ----------------------- Validations --------------------

  validates :performance_measure_id, :date_start, :date_end, :status, :created_by_user_id,
            presence: true

  # ----------------------- Methods --------------------

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      self.all.each do |report|
        csv << report.attributes.values_at(*column_names)
      end
    end
  end

  def self.filter_query(query)
    # Cover cases when the hash is empty (regular index landing)
    # or a query is passed via form POST, but the values are not filled (no value selected in dropdown)
    return all if query.empty? || query.values.all?(&:empty?)
    # Otherwise execute the SQL query (parameters have already been sanitized at this point so we can safely use them)
    self.where(query)
  end
  
end
