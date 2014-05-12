class CreateQuotes < ActiveRecord::Migration
  def change
    create_table :quotes do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.json :terms
      t.string :token
      t.timestamp :expires_at
      t.belongs_to :request, index: true

      t.timestamps
    end
  end
end
