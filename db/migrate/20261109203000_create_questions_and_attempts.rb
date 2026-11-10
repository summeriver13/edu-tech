class CreateQuestionsAndAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :course, null: false, foreign_key: true
      t.string :topic
      t.string :slo
      t.string :kind, null: false, default: "single"
      t.text :stem, null: false
      t.json :choices, null: false, default: []
      t.string :answer, null: false
      t.text :explanation
      t.string :source
      t.timestamps
    end

    create_table :attempts do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.integer :total, null: false, default: 0
      t.datetime :taken_at, null: false
      t.timestamps
    end

    create_table :answers do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :response
      t.boolean :correct, null: false, default: false
      t.timestamps
    end
  end
end
