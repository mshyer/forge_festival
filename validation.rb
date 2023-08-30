class PasswordDigester
  BCrypt::Engine.cost = 12

  def self.encrypt(password)
    BCrypt::Password.create(password)
  end

  def self.check?(password, encrypted_password)
    BCrypt::Password.new(encrypted_password) == password
  end
end

module Validator
  def valid_username?(username)
    @users = YAML.load_file("#{users_path}/users.yaml")
    @users[:users].include?(username.to_sym)
  end

  def valid_password?(username, password)
    @users = YAML.load_file("#{users_path}/users.yaml")
    PasswordDigester.check?(password, @users[:users][username.to_sym])
  end

  def valid_string_length?(string)
    string.length <= 100
  end

  def validate(*parameters)
    error = []
    db = DatabasePersistence.new(PG.connect(dbname: 'forge_festival'))
    parameters.each do |param|
      err = ErrorProcessor.new(params, db).send("#{param}_error".to_sym)
      error << err if err
    end
    error
  end

  def validate_url_params(*parameters)
    error = []
    db = DatabasePersistence.new(PG.connect(dbname: 'forge_festival'))
    parameters.each do |param|
      err = ErrorProcessor.new(params, db).send("#{param}_error".to_sym)
      error << err if err
    end
    redirect_url(error)
  end

  def redirect_url(error)
    if error[0] == "Invalid page number for items list"
      session[:error] = error
      redirect "/forge-team/#{@forge_team_id}"
    elsif error[0] == "Item not found."
      session[:error] = error
      redirect "forge-team/#{@forge_team_id}"
    elsif error != []
      session[:error] = error
      redirect "/rankings"
    end
  end
end

class ErrorProcessor
  def initialize(params, database)
    @params = params
    @database = database
  end

  def credentials_error
    if !valid_username?(@params[:username])
      "Username not found"
    elsif !valid_password?(@params[:username], @params[:password])
      "Invalid username or password"
    end
  end

  def item_id_error
    sql = "SELECT * FROM items WHERE id = $1;"
    item_id = @params[:item_id].to_i
    return "Item not found." if item_id.abs >= 10000
    return "Item not found." if @params[:item_id].match?(/\D/)
    pg_result = @database.query(sql, item_id)
    "Item not found." if pg_result.ntuples != 1
  end

  def forge_team_id_error
    sql = "SELECT * FROM forge_teams WHERE id = $1;"
    forge_team_id = @params[:forge_team_id].to_i
    return "Forge team not found." if forge_team_id.abs >= 10000
    return "Forge team not found." if @params[:forge_team_id].match?(/\D/)
    pg_result = @database.query(sql, forge_team_id)
    "Forge team not found." if pg_result.ntuples != 1
  end

  def rankings_page_number_error
    num_pages = @database.calculate_team_pages
    page = @params[:page]
    "Invalid page number" if !page.to_i.between?(1, num_pages) || page.match?(/\D/)
  end

  def items_page_number_error
    team_id = @params[:forge_team_id]
    num_pages = @database.calculate_item_pages(team_id)
    page = @params[:page]
    "Invalid page number for items list" if !page.to_i.between?(1, num_pages) || page.match?(/\D/)
  end

  def team_name_error
    sql = "SELECT * FROM forge_teams WHERE team_name ILIKE $1;"
    name = @params[:team_name]
    pg_result = @database.query(sql, name)

    string_error = param_string_error(name, "Team name")

    if pg_result.ntuples != 0
      "Team name must be unique"
    elsif string_error
      string_error
    end
  end

  def region_error
    region = @params[:region]
    region_error = param_string_error(region, "region")
    region_error
  end

  def team_leader_error
    tl = @params[:team_leader]
    tl_error = param_string_error(tl, "Team leader")
    tl_error
  end

  def item_name_error
    sql = "SELECT * FROM items WHERE item_name ILIKE $1;"
    name = @params[:item_name]
    pg_result = @database.query(sql, name)

    string_error = param_string_error(name, "Item name")

    if pg_result.ntuples != 0
      "Item name must be unique (even across teams)"
    elsif string_error
      string_error
    end
  end

  def type_error
    type = @params[:type]
    type_error = param_string_error(type, "Item type")
    type_error
  end

  def item_forge_team_id_error
    sql = <<~SQL
    SELECT id FROM forge_teams WHERE id = $1;
    SQL
    id = @params[:forge_team_id]
    pg_result = @database.query(sql, id)
    "Cannot create item at specified forge team id" if pg_result.ntuples != 1
  end

  def quality_error
    quality = @params[:quality]
    if quality.to_i.to_s != quality
      "Quality must be an integer from 0 to 10"
    elsif !quality.to_i.between?(0, 10)
      "Quality out of range. Must be 0-10"
    end
  end

  def beauty_error
    beauty = @params[:beauty]
    if beauty.to_i.to_s != beauty
      "Beauty must be an integer from 0 to 10"
    elsif !beauty.to_i.between?(0, 10)
      "Beauty out of range. Must be 0-10"
    end
  end

  def param_string_error(string, param_name)
    if string == "" || !string
      "#{param_name} must not be empty"
    elsif string.delete(" \n\r") == ""
      "#{param_name} must not be empty"
    elsif !valid_string_length?(string)
      "#{param_name} must be fewer than 100 characters"
    end
  end
end
