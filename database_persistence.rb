require "sinatra/reloader" if development?

class DatabasePersistence
  def initialize(pg_connection)
    @connection = pg_connection
  end

  def query(sql, *params)
    @connection.exec_params(sql, params)
  end

  def close
    @connection.close
  end

  def forge_teams(page)
    sql = "SELECT * FROM forge_teams;"
    start = (page == 1 ? 0 : ((5 * (page - 1))))
    teams = []
    query(sql).each do |tuple|
      tuple["score"] = calculate_points_for_team(tuple["id"])
      teams << tuple
    end
    teams.sort do |t1, t2|
      [t1["score"], t1["team_name"].downcase] <=> [t2["score"], t2["team_name"].downcase]
    end.reverse[start, 5]
  end

  def forge_team(forge_team_id)
    sql = <<~SQL
    SELECT * FROM forge_teams
    WHERE id = $1;
    SQL
    pg_result = query(sql, forge_team_id)
    pg_result[0]
  end

  def item(item_id)
    sql = <<~SQL
    SELECT * FROM items
    WHERE id = $1;
    SQL
    pg_result = query(sql, item_id)
    pg_result[0]
  end

  def update_team_info(team_id, team_name, region, team_leader)
    sql = <<~SQL
    UPDATE forge_teams
    SET team_name = $2
    WHERE id = $1;
    SQL
    query(sql, team_id, team_name)

    sql = <<~SQL
    UPDATE forge_teams
    SET region = $2
    WHERE id = $1;
    SQL
    query(sql, team_id, region)

    sql = <<~SQL
    UPDATE forge_teams
    SET team_leader = $2
    WHERE id = $1;
    SQL
    query(sql, team_id, team_leader)
  end

  def update_item_info(item_id, item_name, type, quality, beauty)
    score = calculate_item_score(quality, beauty)

    sql = <<~SQL
    UPDATE items
    SET item_name = $2
    WHERE id = $1;
    SQL
    query(sql, item_id, item_name)

    sql = <<~SQL
    UPDATE items
    SET type = $2
    WHERE id = $1;
    SQL
    query(sql, item_id, type)

    sql = <<~SQL
    UPDATE items
    SET quality = $2
    WHERE id = $1;
    SQL
    query(sql, item_id, quality)

    sql = <<~SQL
    UPDATE items
    SET beauty = $2
    WHERE id = $1;
    SQL
    query(sql, item_id, beauty)

    sql = <<~SQL
    UPDATE items
    SET score = $2
    WHERE id = $1;
    SQL
    query(sql, item_id, score)
  end

  def items(forge_team_id, page)
    sql = <<~SQL
    SELECT * FROM items
    WHERE forge_team_id = $1;
    SQL
    start = (page == 1 ? 0 : ((5 * (page - 1))))

    pg_result = query(sql, forge_team_id)
    items = []
    pg_result.each { |tuple| items << tuple }
    items.sort do |it1, it2|
      [it1["score"], it1["item_name"].downcase] <=> [it2["score"], it2["item_name"].downcase]
    end.reverse[start, 5]
  end

  def delete_item(item_id)
    sql = <<~SQL
    DELETE FROM items
    WHERE id = $1;
    SQL
    query(sql, item_id)
  end

  def calculate_item_pages(forge_team_id)
    sql = <<~SQL
    SELECT id FROM items
    WHERE forge_team_id = $1;
    SQL
    pg_result = query(sql, forge_team_id)
    (pg_result.ntuples / 5.0).ceil
  end

  def calculate_team_pages
    sql = <<~SQL
    SELECT id FROM forge_teams;
    SQL
    pg_result = query(sql)

    (pg_result.ntuples / 5.0).ceil
  end

  def create_new_team(team_name, region, team_leader)
    sql = <<~SQL
    INSERT INTO forge_teams (team_name, region, team_leader)
      VALUES  ($1, $2, $3);
    SQL
    query(sql, team_name, region, team_leader)
  end

  def delete_forge_team(forge_team_id)
    sql = <<~SQL
    DELETE FROM forge_teams
    WHERE id = $1;
    SQL
    query(sql, forge_team_id)
  end

  def add_team_item(team_id, item_name, type, quality, beauty)
    sql = <<~SQL
    INSERT INTO items (forge_team_id, item_name, type, quality, beauty, score)
      VALUES  ($1, $2, $3, $4, $5, $6);
    SQL
    score = calculate_item_score(quality, beauty)
    query(sql, team_id, item_name, type, quality, beauty, score)
  end

  private

  def calculate_item_score(quality, beauty)
    quality = quality.to_i
    beauty = beauty.to_i
    score = 0
    score += (6 - quality).abs unless quality <= 6
    score += (6 - beauty).abs unless beauty <= 6
    score
  end

  def calculate_points_for_team(team_id)
    sql = <<~SQL
    SELECT sum(score) FROM items
    WHERE forge_team_id = $1;
    SQL
    query(sql, team_id)[0]["sum"].to_i
  end
end
