xquery version "1.0-ml";

module namespace l = "http://marklogic.com/semantics/graph-cities";

(: Application dependant distance estimate function. Must return a number less than the actual distance :)
declare function l:linearDistance($s1 as xs:string,$s2 as xs:string,$triplecache as map:map) as xs:double {
  (: get lon lat for each :)
  (: calculate stright line distance in statute miles (not nautical miles) using lon lats :)
  (:
  let $_ := xdmp:log("lc:linearDistance")
  let $_ := xdmp:log("s1: " || $s1 || ", s2: " || $s2)
  :)
  let $s1cache := map:get($triplecache,$s1)
  (:
  let $_ := xdmp:log("s1cache:-")
  let $_ := xdmp:log($s1cache)
  :)
  let $s2cache := map:get($triplecache,$s2)
  (:
  let $_ := xdmp:log("s2cache:-")
  let $_ := xdmp:log($s2cache)
  :)
  let $s1lon := map:get($s1cache,"http://marklogic.com/semantics/graphqueries#lon")[1]
  let $s1lat := map:get($s1cache,"http://marklogic.com/semantics/graphqueries#lat")[1]
  let $s2lon := map:get($s2cache,"http://marklogic.com/semantics/graphqueries#lon")[1]
  let $s2lat := map:get($s2cache,"http://marklogic.com/semantics/graphqueries#lat")[1]
  (:
  let $_ := xdmp:log("s1lon: " || $s1lon || ", s1lat: " || $s1lat || ", s2lon: " || $s2lon || ", s2lat: " || $s2lat)
  :)
  let $geodist := geo:distance(cts:point(xs:double($s1lat),xs:double($s1lon)),cts:point(xs:double($s2lat),xs:double($s2lon)))
  let $dist := ($geodist,99999.99)[1]
  (:
  let $_ := xdmp:log("linearDistance: " || $dist)
  :)
  return $dist
};

(: Application dependant distance exact calculation function :)
declare function l:exactDistance($s1 as xs:string,$s2 as xs:string,$triplecache as map:map) as xs:double {
  (:
  let $_ := xdmp:log("lc:exactDistance")
  let $_ := xdmp:log("s1: " || $s1 || ", s2: " || $s2)
  :)
  let $s1cache := map:get($triplecache,$s1)
  (:
  let $_ := xdmp:log("s1cache:-")
  let $_ := xdmp:log($s1cache)
  :)
  let $s2cache := map:get($triplecache,$s2)
  (:
  let $_ := xdmp:log("s2cache:-")
  let $_ := xdmp:log($s2cache)
  :)
  let $s1id := map:get($s1cache,"http://marklogic.com/semantics/graphqueries#id")[1] (: multiples possible :)
  let $s2id := map:get($s2cache,"http://marklogic.com/semantics/graphqueries#id")[1]
  (:
  let $_ := xdmp:log("s1id:-")
  let $_ := xdmp:log($s1id)
  let $_ := xdmp:log("s2id:-")
  let $_ := xdmp:log($s2id)
  :)
  let $s1dist2 := map:get($s1cache,"http://marklogic.com/semantics/graphqueries#distanceTo_" || $s2id)
  let $s2dist1 := map:get($s2cache,"http://marklogic.com/semantics/graphqueries#distanceTo_" || $s1id)
  let $dist := ($s1dist2,$s2dist1,9999999.99)[1] (: data may exist in one entity, the other entity, or both - only return once :)
  (: large number is for nodes that do not have distances (I only pulled in a few from the source dataset) :)
  (: let $_ := xdmp:log("exactDistance: " || $dist) :)
  return xs:double($dist)
};
