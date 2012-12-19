CREATE TABLE uw_ingredient(uw_id integer NOT NULL, uw_ingredient text NOT NULL, 
                            uw_full text NOT NULL,
 PRIMARY KEY (uw_id),
  CONSTRAINT uw_ingredient_Ingredient UNIQUE (uw_ingredient)
 );
 
 CREATE TABLE uw_combo(uw_id integer NOT NULL, 
                        uw_ingredientid integer NOT NULL, 
                        uw_with text NOT NULL, uw_link text NOT NULL, 
                        uw_rating integer NOT NULL,
  PRIMARY KEY (uw_id),
   CONSTRAINT uw_combo_IngredientId
    FOREIGN KEY (uw_ingredientId) REFERENCES uw_ingredient (uw_id)
  );
  
  