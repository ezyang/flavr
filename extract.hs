import Text.HTML.TagSoup
import Debug.Trace
import Data.List
import Data.Char
import Control.Exception hiding (try)
import System.IO.Unsafe
import Text.Parsec
import Text.Parsec.Pos
import Database.SQLite.Simple
import Control.Monad
import Data.String

-- OK what visualizations do we want:
--      * a graph (this implies we need to de-duplicate, clean up the
--        data, and deal with the terrifying "comma" entries which
--        have a bazillion things built into it
--          - Given the graph, what are "clusters" of flavors?
--            Do these correspond to types of cuisine?
--          - What does the clustering look like when you take
--            method of preparation into account?
--      * what ingredients have the most pairings? (simple)

-- XXX maybe an easier to build mobile phone app just cuts up the
-- book into all of the ingredients and has a SEARCH box.  Maybe
-- hyperlinks would be nice too

data Rating = Low | Medium | High | Classic
    deriving (Show, Eq, Ord, Enum)
data Entry = Entry { name :: String, full :: String, matches :: [Combo] }
    deriving (Show)
data Combo = Combo { matchName :: String, link :: String, rating :: Rating }
    deriving Show
-- note that "Low" is still a real pairing!

-- mapM_ putStrLn . map full . filter (null . matches) $ r
handleFile = filter (not . null . matches) -- XXX aliases are useful info
           . map handleIngredient
           . partitions (\x -> x ~== TagOpen "p" [("class", "lh1")] || x ~== TagOpen "p" [("class", "lh")])

-- XXX deal with commas (contains "and")
-- XXX deal with colons / one approximation is to divide into 'main' and
-- 'qualifiers'
-- XXX deal with parentheticals
-- XXX deal with "esp."

-- this is a pretty cool trick: turn runs of tags into tokens and then
-- parse over that
parsePred p = token renderTags (const (initialPos "<unknown>")) (\x -> if p x then Just x else Nothing)
tag t = parsePred (any (~== t))
ptag cl = tag (TagOpen "p" [("class", cl)])

parseIngredient = do
    fullingredient <- fmap (strip . map toLower . innerText) (ptag "lh" <|> ptag "lh1")
    -- sometimes the preamble is marked in the classes; take advantage
    -- appropriately
    many (try (many (ptag "ul") >> many1 (ptag "ul3")))
    optional (try (many1 (ptag "ul") >> lookAhead (ptag "ul1")))
    -- parse the actual things (and combine them together)
    -- it's an OR because sometimes there are interspersed other
    -- sections, and after they conclude you get back an ul1
    matches' <- many (ptag "ul1" <|> ptag "ul") -- some ingredients don't have pairings, so don't use many1
    -- get rid of the extra bits
    optional (try (many (ptag "h4" >> many (ptag "ul"))))
    -- done
    eof
    -- post-processing
    let matches = map handleEntry
                . filter filterEntry
                . map (takeWhile (~/= TagClose "p")) -- doesn't work if there is nested p, fortunately, there is not!
                . takeWhile (all (~/= TagText "AVOID"))
                $ matches'
        ingredient = removeParentheticals fullingredient
    return (Entry ingredient fullingredient matches)

handleIngredient x =
    let Right r = runParser parseIngredient () "<unknown>"            -- regex over token structure
                . filter ((`elem` datum) . fromAttrib "class" . head) -- drop irrelevant tokens
                . partitions (~== TagOpen "p" [])                     -- tokenize
                $ x
    in r

rt a = trace (show a) $ a
pp xs a = (unsafePerformIO $ mapM_ print xs) `seq` a

removeParentheticals x =
 strip $ case span (/= '(') x of
            (a@"african cuisine ", r) -> case r of
                '(':'s':'e':_ -> a
                _ -> a ++ "(" ++ takeWhile (/= '(') (tail r)
            (r,_) -> r

datum = ["lh", "lh1", "ul", "ul1", "ul3", "h4"]
meta = ["p1", "ca", "img", "boxh", "ext", "exts", "ca3", "", "sbh", "sbtx1", "sbbl", "sbbl3", "sbtx", "sbtx3", "sbtx4", "box1", "sbbl1", "bl", "bl1", "bl3", "ep", "eps", "bp", "bp1", "bp3", "ext4", "sbtx11", "sbtx31"]

filterEntry x =
    not (head (tail x) ~== TagOpen "strong" [] && innerText [head (tail (tail x))] `elem` ["Season:", "Taste:", "Weight:", "Volume:", "Botanical relatives:", "Function:", "Techniques:", "Techniques/Tips:", "Botanical relative:"])

handleEntry x =
    let rawname = strip . innerText $ x
        name = map toLower . (if isClassic then tail else id) $ rawname
        isClassic = head rawname == '*'
        isHigh = isMedium && (any (not . any isLower) . filter (any isAlpha) $ words rawname)
        isMedium = any (~== TagOpen "strong" []) x
    in Combo
        name
        (removeParentheticals name)
        (if isClassic then Classic else if isHigh then High else if isMedium then Medium else Low)

strip = unwords . filter (not . null) . words
collapse [] = []
collapse (x:xs) = x : go x xs
    where go r (x:xs) | r == x = go r xs
                      | otherwise = x : go x xs
          go _ [] = []

as = sort ((map (:[]) (['a'..'i'] ++ ['m','s','t'])) ++ ["jkl", "nop", "qr"])
v a = unsafePerformIO $ readFile ("TFB/OEBPS/Text/FlavorBible_chap-3" ++ a ++ ".html")
r = concatMap (handleFile . parseTags) $ map v as

writeOut = do
    h <- open "backend/flavr.sqlite3"
    forM_ r $ \(Entry nm fnm ms) -> do
        execute h (fromString "insert into uw_ingredient (uw_ingredient, uw_full) values (?, ?)") (nm, fnm)
        (Only id:_) <- query_ h (fromString "select last_insert_rowid() from uw_ingredient")
        forM_ ms $ \(Combo with link rating) -> do
            execute h (fromString "insert into uw_combo (uw_ingredientid, uw_with, uw_link, uw_rating) values (?,?,?,?)") (id :: Int, with, link, fromEnum rating)
    close h

main = writeOut
