open Tags

style ratelow
style ratemedium
style ratehigh
style rateclassic
style rateunknown

table ingredient : { Id : int, Ingredient : string }
    PRIMARY KEY Id
    CONSTRAINT Ingredient UNIQUE Ingredient

(* 0 to 3, 0 = Normal, 1 = Bold, 2 = BOLD, 3 = *CLASSIC *)
table combo : { Id : int, IngredientId : int, With : string, Rating : int }
    PRIMARY KEY Id
    CONSTRAINT IngredientId FOREIGN KEY IngredientId REFERENCES ingredient(Id)

fun rating r =
  if r = 0 then ratelow
  else if r = 1 then ratemedium
  else if r = 2 then ratehigh
  else if r = 3 then rateclassic
  else rateunknown

fun decorate cb xb =
  <xml><active code={
    id <- fresh;
    return <xml>{xb id}<active code={cb id; return <xml/>} /></xml>
  } /></xml>

fun template title b : page = <xml>
  <head>
    <link rel="stylesheet" type="text/css" href="http://code.jquery.com/mobile/1.2.0/jquery.mobile-1.2.0.min.css" />
    <link rel="stylesheet" type="text/css" href="http://localhost/flavr/backend/flavr.css" />
    {unsafeHtml "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"}
  </head>
  <body>
    {unsafeHtml "<div data-role=\"page\"><div data-role=\"header\">"}
      (* For some odd reason this particular markup cannot be done dynamically *)
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

(* Very delicately avoid all dynamic-ness, so that jQuery Mobile's AJAX can do its magic *)
and display (ing : string) : transaction page =
  r <- queryX (SELECT combo.With, combo.Rating FROM combo INNER JOIN ingredient ON ingredient.Id = combo.IngredientId WHERE ingredient.Ingredient = {[ing]})
         (fn r => <xml><li class={rating r.Combo.Rating}>{[r.Combo.With]}</li></xml>);
  return (template ing <xml>
    {unsafeHtml "<ul data-role=\"listview\">"}
    {r}
    {unsafeHtml "</ul>"}
  </xml>)
