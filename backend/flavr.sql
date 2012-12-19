CREATE TABLE uw_Flavr_ingredient(uw_ingredientid int8 NOT NULL, 
                                  uw_ingredient text NOT NULL,
 PRIMARY KEY (uw_ingredientId),
  CONSTRAINT uw_Flavr_ingredient_Ingredient UNIQUE (uw_ingredient)
 );
 
 CREATE TABLE uw_Flavr_combo(uw_comboid int8 NOT NULL, 
                              uw_ingredientid int8 NOT NULL, 
                              uw_with text NOT NULL, uw_rating int8 NOT NULL,
  PRIMARY KEY (uw_comboId)
   
  );
  
  