open Tags

table ingredient : { Id : int, Ingredient : string }
    PRIMARY KEY Id
    CONSTRAINT Ingredient UNIQUE Ingredient

table combo : { Id : int, IngredientId : int, With : string, Rating : int }
    PRIMARY KEY Id
    CONSTRAINT IngredientId FOREIGN KEY IngredientId REFERENCES ingredient(Id)

fun decorate cb xb =
  <xml><active code={
    id <- fresh;
    return <xml>{xb id}<active code={cb id; return <xml/>} /></xml>
  } /></xml>

fun template title b : page = <xml>
  <head>
    <link rel="stylesheet" type="text/css" href="http://code.jquery.com/mobile/1.2.0/jquery.mobile-1.2.0.min.css" />
    {unsafeHtml "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"}
  </head>
  <body>
    {unsafeHtml "<div data-role=\"page\"><div data-role=\"header\">"}
      {unsafeHtml (strcat (strcat "<a href=\"" (show (url (main ())))) "\" data-icon=\"home\">Home</a>")}
      <h1>
        {[title]}
      </h1>
    {unsafeHtml "</div><div data-role=\"content\">"}
      {b}
    {unsafeHtml "</div></div>"}
  </body>
</xml>

and main () : transaction page =
  r <- queryX (SELECT ingredient.Ingredient FROM ingredient ORDER BY ingredient.Ingredient ASC)
          (fn r =>
            let val x = r.Ingredient.Ingredient in
            <xml><li><a link={display x}>{[x]}</a></li></xml>
            end);
  return (template "flavr" <xml>
    {decorate (fn id => addAttribute "data-role" "listview" id; addAttribute "data-filter" "true" id) (fn id => <xml><ul id={id}>
      {r}
    </ul></xml>)}
  </xml>)

(*
  ing <- source "";
  ingid <- fresh;
    {decorate (addAttribute "class" "ui-hidden-accessible") (fn id => <xml><label for={ingid} id={id}>Ingredient:</label></xml>)}
    <ctextbox source={ing} id={ingid}/>
    <active code={addAttribute "placeholder" "Ingredient" ingid; return <xml/>} />
    <button value="Go" onclick={fn _ => i <- get ing; redirect (url (display i)) }/>
*)

and display (ing : string) : transaction page =
  r <- queryX (SELECT combo.With FROM combo INNER JOIN ingredient ON ingredient.Id = combo.IngredientId WHERE ingredient.Ingredient = {[ing]})
         (fn r => <xml><li>{[r.Combo.With]}</li></xml>);
  return (template ing <xml>
    {unsafeHtml "<ul data-role=\"listview\">"}
    {r}
    {unsafeHtml "</ul>"}
  </xml>)

(*
    {decorate (addAttribute "data-role" "listview") (fn id => <xml><ul id={id}>
      {r}
    </ul></xml>)}
    *)
