import Text.HTML.TagSoup
import Debug.Trace
import Data.List
import Data.Char

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
    deriving (Show, Eq, Ord)
data Entry = Entry { name :: String, matches :: [Match] }
    deriving (Show)
data Match = Match { matchName :: String, orig :: String, rating :: Rating }
    deriving Show
-- note that "Low" is still a real pairing!

-- yeah I'm a terrible person
-- XXX gotta fix encoding (looks like the docs aren't perfectly encoded either
-- XXX remove trailing whitespace
handleFile = map handleIngredient
           . partitions (\x -> x ~== TagOpen "p" [("class", "lh1")] || x ~== TagOpen "p" [("class", "lh")])

-- XXX deal with commas

strip = unwords . filter (not . null) . words

handleIngredient x =
    let name = strip . map toLower . fromTagText . head . tail $ x
        entries = map handleEntry
                . filter filterEntry
                . map (takeWhile (~/= TagClose "p")) -- doesn't work if there is nested p, fortunately, there is not!
                . takeWhile (all (~/= TagOpen "p" [("class", "h4")])) -- chop off pairings
                . takeWhile (all (~/= TagText "AVOID")) -- chop off AVOID (not a map, because AVOID is a divider)
                . map tail
                . partitions (\y -> y ~== TagOpen "p" [("class", "ul")] || y ~== TagOpen "p" [("class", "ul1")]) $ x
    in Entry name entries

-- XXX deal with tips that bleed over into the list (maybe do an alpha
-- check)
filterEntry x =
    not (head x ~== TagOpen "strong" [] && innerText [head (tail x)] `elem` ["Season:", "Taste:", "Weight:", "Volume:", "Botanical relatives:", "Function:", "Techniques:", "Techniques/Tips:", "Botanical relative:"])

handleEntry x =
    let name = strip . innerText $ x
        isClassic = head name == '*'
        isHigh = isMedium && (any (not . any isLower) . filter (any isAlpha) $ words name)
        isMedium = any (~== TagOpen "strong" []) x
    in Match name (renderTags x) (if isClassic then Classic else if isHigh then High else if isMedium then Medium else Low)

as = sort ((map (:[]) (['a'..'i'] ++ ['m','s','t'])) ++ ["jkl", "nop", "qr"])
v a = readFile ("TFB/OEBPS/Text/FlavorBible_chap-3" ++ a ++ ".html")
r = concatMap (handleFile . parseTags) `fmap` mapM v as
