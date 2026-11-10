class AddLessonToQuestionsAndAttempts < ActiveRecord::Migration[8.1]
  def change
    add_reference :questions, :lesson, foreign_key: true
    add_reference :attempts, :lesson, foreign_key: true
  end
end
