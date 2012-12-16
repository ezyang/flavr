import Text.HTML.TagSoup
import Debug.Trace
import Data.List
import Data.Char
import Control.Exception hiding (try)
import System.IO.Unsafe
import Text.Parsec
import Text.Parsec.Pos

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
data Entry = Entry { name :: String, matches :: [Match] }
    deriving (Show)
data Match = Match { matchName :: String, orig :: String, rating :: Rating }
    deriving Show
-- note that "Low" is still a real pairing!

handleFile = map handleIngredient
           . partitions (\x -> x ~== TagOpen "p" [("class", "lh1")] || x ~== TagOpen "p" [("class", "lh")])

-- XXX deal with commas (contains "and")
-- XXX deal with colons / one approximation is to divide into 'main' and
-- 'qualifiers'
-- XXX deal with parentheticals
-- XXX deal with "esp."

parsePred p = token renderTags (const (initialPos "<unknown>")) (\x -> if p x then Just x else Nothing)
tag t = parsePred (any (~== t))
ptag cl = tag (TagOpen "p" [("class", cl)])

parseIngredient :: Parsec [[Tag String]] u ()
parseIngredient = do
    ingredient <- (ptag "lh" <|> ptag "lh1")
    -- sometimes the preamble is marked in the classes; take advantage
    -- appropriately
    many (try (many (ptag "ul") >> many1 (ptag "ul3")))
    optional (try (many1 (ptag "ul") >> lookAhead (ptag "ul1")))
    -- parse the actual things (and combine them together)
    matches <- many (ptag "ul1" <|> ptag "ul") -- some ingredients don't have pairings, so don't use many1
    -- get rid of the extra bits
    optional (try (many (ptag "h4" >> many (ptag "ul"))))
    -- done
    eof
    -- trace (show (dropWhile (not . filterEntry . tail) matches)) $ return ()

handleIngredient x =
    let name = strip . map toLower . fromTagText . head . tail $ x
        entries = map handleEntry
                . filter filterEntry
                . map (takeWhile (~/= TagClose "p")) -- doesn't work if there is nested p, fortunately, there is not!
                . takeWhile (all (~/= TagOpen "p" [("class", "h4")])) -- chop off pairings
                . takeWhile (all (~/= TagText "AVOID")) -- chop off AVOID (not a map, because AVOID is a divider)
                -- . dropWhile (any (~== TagOpen "p" [("class", "ul3")]))
                -- . map tail
                -- [<p class="ul">beans</p>]
                . partitions (\y -> y ~== TagOpen "p" [("class", "ul")] || y ~== TagOpen "p" [("class", "ul1")])
                -- <p class="lh1">INGREDIENT</p><p class="ul">beans</p>
                $ x
        Right foo = rt $ runParser parseIngredient () "<unknown>" (filter ((`elem` datum) . fromAttrib "class" . head) . partitions (~== TagOpen "p" []) $ x)
        structure = filter (`elem` datum) . map (fromAttrib "class" . head) . partitions (~== TagOpen "p" []) $ x
    in -- trace name $ trace (show structure) $
       -- pp (map innerText . filter ((`elem` meta) . fromAttrib "class" . head)  . partitions (~== TagOpen "p" []) $ x)
       foo `seq` Entry name entries

rt a = trace (show a) $ a
pp xs a = (unsafePerformIO $ mapM_ print xs) `seq` a

datum = ["lh", "lh1", "ul", "ul1", "ul3", "h4"]
meta = ["p1", "ca", "img", "boxh", "ext", "exts", "ca3", "", "sbh", "sbtx1", "sbbl", "sbbl3", "sbtx", "sbtx3", "sbtx4", "box1", "sbbl1", "bl", "bl1", "bl3", "ep", "eps", "bp", "bp1", "bp3", "ext4", "sbtx11", "sbtx31"]

-- XXX deal with tips that bleed over into the list (maybe do an alpha check)
filterEntry x =
    not (head x ~== TagOpen "strong" [] && innerText [head (tail x)] `elem` ["Season:", "Taste:", "Weight:", "Volume:", "Botanical relatives:", "Function:", "Techniques:", "Techniques/Tips:", "Botanical relative:"])

handleEntry x =
    let name = strip . innerText $ x
        isClassic = head name == '*'
        isHigh = isMedium && (any (not . any isLower) . filter (any isAlpha) $ words name)
        isMedium = any (~== TagOpen "strong" []) x
    in Match (map toLower name) (renderTags x) (if isClassic then Classic else if isHigh then High else if isMedium then Medium else Low)

strip = unwords . filter (not . null) . words
collapse [] = []
collapse (x:xs) = x : go x xs
    where go r (x:xs) | r == x = go r xs
                      | otherwise = x : go x xs
          go _ [] = []

as = sort ((map (:[]) (['a'..'i'] ++ ['m','s','t'])) ++ ["jkl", "nop", "qr"])
v a = readFile ("TFB/OEBPS/Text/FlavorBible_chap-3" ++ a ++ ".html")
r = concatMap (handleFile . parseTags) `fmap` mapM v as
