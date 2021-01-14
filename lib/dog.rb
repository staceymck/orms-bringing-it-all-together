require 'pry'
class Dog
  attr_accessor :name, :breed, :id

  def initialize(name:, breed:, id: nil)
    @name = name
    @breed = breed
    @id = id
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE IF EXISTS dogs")
  end

  def save
    if self.id
      update
    else
      sql = <<-SQL
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
    end
   
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    self
  end

  def self.create(attributes)
    Dog.new(attributes).save
  end

  def self.new_from_db(row)
    Dog.new(id:row[0], name:row[1], breed:row[2])
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
    SQL

    DB[:conn].execute(sql, id).map do |row| #returns the instance inside [], so .first is needed to accesses array contents
      new_from_db(row)  
    end.first
  end

  def self.find_or_create_by(name:, breed:)
    sql = <<-SQL
      SELECT * FROM dogs 
      WHERE name = ? AND breed = ?
    SQL
    dog_array = DB[:conn].execute(sql, name, breed)

    if !dog_array.empty?
      new_from_db(dog_array[0])
    else
      create(name: name, breed: breed)
    end
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
    SQL

    DB[:conn].execute(sql, name).map do |row|
      new_from_db(row)
    end.first
  end

  def update
    sql = <<-SQL
    UPDATE dogs SET name = ?, breed = ? WHERE id = ?
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
end