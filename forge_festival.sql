CREATE TABLE forge_teams (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  team_name varchar(100) UNIQUE NOT NULL,
  region varchar(100) NOT NULL,
  team_leader varchar(100) NOT NULL

);

CREATE TABLE items (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  item_name varchar(100) UNIQUE NOT NULL,
  type varchar(100) NOT NULL,
  forge_team_id integer REFERENCES forge_teams(id) ON DELETE CASCADE NOT NULL,
  quality integer CHECK (quality BETWEEN 0 AND 10) NOT NULL,
  beauty integer CHECK (quality BETWEEN 0 AND 10) NOT NULL,
  score integer CHECK (score BETWEEN 0 AND 8) NOT NULL
);

INSERT INTO forge_teams (team_name, region, team_leader)
  VALUES  ('The Hammerers of Kol''Farod', 'Kol''Farod', 'Werden Brightgrog'),
          ('Clink ''n Clank', 'Etibia', 'Kiddel Ingotmane'),
          ('Ore Decor', 'Mannfallheimr', 'Helgred Deepmaul'),
          ('The Runemaster''s Guildforge', 'Domrland', 'Daloton Runespine'),
          ('Hammer and Tongs', 'Northland', 'Hokerlig Gravelfoot'),
          ('He Who Smelt It', 'The Putrid Hills', 'Brorhath Bonegrip');
          

INSERT INTO items  (item_name, type, quality, beauty, score, forge_team_id)
  VALUES  ('Piece Maker', 'Warhammer', 7, 4, 1, 1),
          ('Edge of Ruin', 'Battle Axe', 5, 8, 2, 1),
          ('Vindictive Barrier', 'Shield', 6, 5, 0, 1),
          ('Shadow Titanium Greaves', 'Leg Armor', 8, 8, 4, 1),
          ('Undead Spear', 'Spear', 7, 7, 2, 1),
          ('Helmet of Vigor', 'Helmet', 4, 4, 0, 1),
          ('Twisted Mithril Gunbelt', 'Belt', 9, 9, 6, 1),
          ('Toothpick', 'Sword', 2, 3, 0, 2),
          ('Interrogator', 'Dagger', 7, 1, 1, 2),
          ('Frenzy', 'Sword', 5, 5, 0, 2),
          ('Infused Guard', 'Shield', 7, 6, 1, 2),
          ('Warrior Tower Shield', 'Shield', 4, 4, 0, 2),
          ('Chainmail Armor', 'Chest Armor', 4, 3, 0, 2),
          ('Steel Chestplate of Shattered Hell', 'Chest Armor', 8, 6, 2, 2),
          ('Blinkstrike', 'Battle Axe', 6, 6, 0, 2),
          ('Eternal Ravager', 'Battle Axe', 4, 4, 0, 2),
          ('Phantom Titanium Arbalest', 'Crossbow', 7, 7, 2, 2),
          ('Renewed Battlehammer', 'Warhammer', 3, 4, 0, 2),
          ('Brutality', 'Warhammer', 7, 1, 1, 2),
          ('Reforged Steel Greaves', 'Greaves', 3, 5, 0, 2),
          ('Smooth Spike', 'Spear', 6, 3, 0, 2),
          ('Heartstriker', 'Sword', 6, 6, 0, 2),
          ('Gladius', 'Sword', 5, 5, 0, 2),
          ('Desolation Armor of Fire', 'Chest Armor', 8, 7, 3, 3),
          ('Ebon Wall', 'Shield', 7, 7, 2, 3),
          ('Homage', 'War Hammer', 8, 7, 3, 3),
          ('Fierce Shadowsteel Lance', 'Spear', 7, 7, 2, 3),
          ('Persuasion', 'Sword', 9, 8, 5, 3),
          ('The Grudge', 'Warhammer', 10, 10, 8, 4),
          ('Kilt of Demonic Memories', 'Leg Armor', 10, 10, 8, 4),
          ('Hero''s Calling', 'Shield', 10, 10, 8, 4),
          ('Mithril Helm of the Deep Vaults', 'Helmet', 10, 10, 8, 4),
          ('Runed Blade of the Endless Depths', 'Sword', 10, 10, 8, 4);
