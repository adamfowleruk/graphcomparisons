xquery version "1.0-ml";
module namespace l = "http://marklogic.com/semantics/graph";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

declare function l:astar($subjectIri as xs:string, $targetIri as xs:string,
  $hFunction as function(xs:string,xs:string,map:map) as item()*,
  $dFunction as function(xs:string,xs:string,map:map) as item()*,
  $neighbourQuery as xs:string) {
  (: From here: https://en.wikipedia.org/wiki/A*_search_algorithm#Pseudocode :)
  let $openset := map:map()
  let $_ := map:put($openset,$subjectIri,"in")
  let $closedset := map:map()
  (: also "closedset" => () :)


  let $triplecache := map:map()
  (: pre-populate triple cache for this subject :)
  let $params := map:map()
  (: cache for subject :)
(:
  let $_ := xdmp:log("********** INITIAL BLANK TRIPLE MAP:- ")
  let $_ := xdmp:log($triplecache)

  let $_ := xdmp:log("********** NOW CACHING SOURCE IRI TRIPLES")
:)
  let $_ := map:put($params,"neighbour",sem:iri($subjectIri))
  let $cachemapSource := map:map()
  let $tcput :=
    (: WARNING: SPARQL QUERY DOES NOT RETURN BOUND VARIABLES, EVEN IF SELECTED!!! :)
    for $neighbour in <item>${sem:sparql("select ?neighbour ?p ?o WHERE {?neighbour a <http://marklogic.com/semantics/graphqueries#city> . ?neighbour ?p ?o .}",$params)}</item>/json:object
    let $pred := xs:string($neighbour/json:entry[@key = "p"]/json:value)
    let $obj := xs:string($neighbour/json:entry[@key = "o"]/json:value)
    (: let $_ := xdmp:log("CACHING: " || $subjectIri || " " || $pred || " " || $obj) :)
    let $_ := map:put($cachemapSource,$pred,(map:get($cachemapSource,$pred),$obj))
    (: let $_ := (xdmp:log("Cache now:-"),xdmp:log($cachemap)) :)
    return ()
  (: let $_ := xdmp:log("CACHEMAPSOURCE:-")
  let $_ := xdmp:log($cachemapSource) :)
  let $_ := map:put($triplecache,$subjectIri,$cachemapSource)
  (:
  let $_ := xdmp:log("fetched cachemapsource:-")
  let $_ := xdmp:log(map:get($triplecache,$subjectIri)) (: this works and prints correctly :)


  let $_ := xdmp:log("********** NOW CACHING TARGET IRI TRIPLES") :)

  (: Now cache for target :)
  let $_ := map:put($params,"neighbour",sem:iri($targetIri))
  let $cachemapTarget := map:map()
  let $tcput :=
    (: WARNING: SPARQL QUERY DOES NOT RETURN BOUND VARIABLES, EVEN IF SELECTED!!! :)
    for $neighbour in <item>${sem:sparql("select ?neighbour ?p ?o WHERE {?neighbour a <http://marklogic.com/semantics/graphqueries#city> . ?neighbour ?p ?o .}",$params)}</item>/json:object
    let $pred := xs:string($neighbour/json:entry[@key = "p"]/json:value)
    let $obj := xs:string($neighbour/json:entry[@key = "o"]/json:value)
    (: let $_ := xdmp:log("CACHING: " || $niri || " " || $pred || " " || $obj) :)
    let $_ := map:put($cachemapTarget,$pred,(map:get($cachemapTarget,$pred),$obj))
    (: let $_ := (xdmp:log("Cache now:-"),xdmp:log($cachemap)) :)
    return ()

  let $_ := map:put($triplecache,$targetIri,$cachemapTarget)
  (:
  let $_ := xdmp:log("fetched cachemapTarget:-")

  let $_ := xdmp:log(map:get($triplecache,$targetIri)) (: this works and prints correctly :)
:)

  (:
  let $_ := xdmp:log("********** l:astar")
  :)


  let $gscore := map:map()
  let $_ := map:put($gscore,$subjectIri,0)
  let $fscore := map:map()
  let $_ := map:put($fscore,$subjectIri,$hFunction($subjectIri,$targetIri,$triplecache))

  let $camefrom := map:map()

  return
    l:nextStep($targetIri,$openset,$closedset,$gscore,$fscore,$hFunction,$dFunction,$camefrom,$neighbourQuery,$triplecache)
};

declare function l:nextStep($targetIri as xs:string,$openset as map:map,$closedset as map:map,$gscore as map:map,$fscore as map:map,
  $hFunction as function(xs:string,xs:string,map:map) as item()*,$dFunction as function(xs:string,xs:string,map:map) as item()*,
  $camefrom as map:map,$neighbourQuery as xs:string,$triplecache as map:map) {
    (: let $_ := xdmp:log("********** l:nextStep") :)


  if (fn:empty(map:keys($openset))) then
    ( (:xdmp:log("********** FAILURE"):) ) (: FAILURE :)
  else
    (: step in while loop, and recursively call ourself :)
    let $temp := map:map()
    let $_ := map:put($temp,"minscore",9999999999.99)
    (: let $_ := xdmp:log("***** Finding openset iri with lowest fscore") :)
    let $currentLoop :=
      for $iri in map:keys($openset)
      let $fs := map:get($fscore,$iri)
      (: let $_ := xdmp:log("Openset contains " || $iri || " with fscore: " || $fs) :)
      return
        if ($fs lt map:get($temp,"minscore")) then
          let $_ := map:put($temp,"minscore",$fs)
          let $_ := map:put($temp,"miniri",$iri)
          (: let $_ := xdmp:log("Found new lowest score " || $fs || " via subject " || $iri) :)
          return ()
        else ()
    let $current := map:get($temp,"miniri")
    (: let $_ := xdmp:log("***** NEW CURRENT: " || $current) :)
    return
      if ($current = $targetIri) then
        (: let $_ := xdmp:log("********** SUCCESS!!! CONSTRUCTING SOLUTION PATH!") :)
         l:reconstructPath($camefrom,$targetIri,()) (: SUCCESS!!! :)
      else
        let $_ := map:delete($openset,$current)
        let $_ := map:put($closedset,$current,"in")
        let $params := map:map()
        let $_ := map:put($params,"left",sem:iri($current))
        let $res := sem:query-results-serialize(sem:sparql($neighbourQuery,$params,("optimize=0")),"xml")/sr:results/sr:result
        let $iris := (: THIS NEXT SECTION EATS 49% OF ALL EXECUTION TIME :)
          for $neighbour in $res
          let $niri := $neighbour/sr:binding[@name = "neighbour"]/sr:uri/text()
          let $cachemap := map:get($triplecache,$niri)
          let $cachemap := if (fn:empty($cachemap)) then map:map() else $cachemap
          let $pred := $neighbour/sr:binding[@name = "p"]/sr:uri/text()

          let $_ := map:put($cachemap,$pred,(map:get($cachemap,$pred), $neighbour/sr:binding[@name = "o"]/element()/text()))
          let $_ := map:put($triplecache,$niri,$cachemap)
          return $niri

        let $neighbours :=
         (:)
         let $cache := map:get($triplecache,$current)
         let $_ := xdmp:log("Cached triples for iri: " || $current || " :-")
         let $_ := xdmp:log($cache)
         return if(fn:empty($cache)) then

          let $_ := xdmp:log("***** Empty cache for subject: " || $current || ", performing sparql query...")
          :)
           (:)
            for $neighbour in <item>${sem:sparql($neighbourQuery,$params)}</item>/json:object
            let $niri := xs:string($neighbour/json:entry[@key = "neighbour"]/json:value)
            :)
            fn:distinct-values($iris)
         (: else
          fn:distinct-values(map:get($cache,"http://marklogic.com/semantics/graphqueries#near")) :)
        (:
        let $_ := xdmp:log("Neighbour IRIs:-")
        let $_ := xdmp:log($neighbours)
        :)
        return (
          for $neighbour in $neighbours (: TODO ensure this works in a recursive function :)
          (: let $_ := xdmp:log("Evaluating neighbour: " || $neighbour) :)
          return
            if (fn:not(fn:empty(map:get($closedset,$neighbour)))) then
              ( (:xdmp:log("Neighbour already processed, skipping") :) )
            else
              (: let $_ := xdmp:log(" - calling exact score function for neighbour") :)
              let $tentativegscore := map:get($gscore,$current) + $dFunction($current,$neighbour,$triplecache)
              (: let $_ := xdmp:log("Tentative Score: " || xs:string($tentativegscore)) :)
              return
                (
                if (fn:empty(map:get($openset,$neighbour))) then
                  (
                    map:put($openset,$neighbour,"in") (:,
                    xdmp:log("Neighbour placed in to open set") :)
                  )
                else
                  if ($tentativegscore >= map:get($gscore,$neighbour)) then
                    ( (:xdmp:log("Too costly, skipping"):) )
                  else ()
                ,
                    (: let $_ := xdmp:log("Processing neighbours' neighbours next for " || $neighbour) :)
                    let $_ := map:put($camefrom,$neighbour,$current)
                    let $_ := map:put($gscore,$neighbour,$tentativegscore)
                    let $_ := map:put($fscore,$neighbour,$tentativegscore + $hFunction($neighbour,$targetIri,$triplecache) )
                    (: let $_ := xdmp:log("fscore for " || $neighbour || " is " || map:get($fscore,$neighbour)) :)
                    return ()
                )
              ,
              l:nextStep($targetIri,$openset,$closedset,$gscore,$fscore,$hFunction,$dFunction,$camefrom,$neighbourQuery,$triplecache)
              )
};

declare function l:reconstructPath($camefrom as map:map,$targetIri as xs:string?,$patharr as xs:string*) {
  if (fn:empty($targetIri)) then $patharr else
    let $nodeIri := map:get($camefrom,$targetIri)
    return l:reconstructPath($camefrom,$nodeIri,($patharr,$targetIri))
};
