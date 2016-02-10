#!/usr/bin/env node

var fs = require("fs");

// using data from: https://people.sc.fsu.edu/~jburkardt/datasets/cities/cities.html

// load all 4 files, synchronously
var dists = fs.readFileSync("../data/raw/sgb128_dist.txt","utf-8").split("\n");
var lonlats = fs.readFileSync("../data/raw/sgb128_dms.txt","utf-8").split("\n");
var names = fs.readFileSync("../data/raw/sgb128_name.txt","utf-8").split("\n");
var populations = fs.readFileSync("../data/raw/sgb128_weight.txt","utf-8").split("\n");

var cities = [];

var removeBlanks = function(arr) {
  var res = [];
  for (var k = 0;k < arr.length;k++) {
    if (""!= arr[k]) {
      res.push(arr[k]);
    }
  }
  return res;
};

var processLine = function(line,pos,arr,str) {
  if (pos > line.length) {
    // add last str first!
    if ("" != str) {
      //console.log("Saving number: " + num);
      arr.push(str);
    }
    return arr;
  }
  var ch = line.substring(pos,pos + 1);
  //console.log("Char at pos: " + pos + " = " + ch);
  if (" " == ch) {
    if ("" != str) {
      //console.log("Saving number: " + num);
      arr.push(str);
      str = "";
    }
  } else {
    str = str + ch;
  }
  return processLine(line,pos + 1,arr,str);
};

// for each line (128 lines in every file)
var ids = {};
for (var i = 0,distLine,lonlatLine,nameLine,popLine; i < 128;i++) {
  // pull in raw data
  //distLine = removeBlanks(dists[i].replace(/\s*/gi,",") /*.split(",")*/);
  distLine = processLine(dists[i],0,new Array(),"");
  lonlatLine = processLine(lonlats[i],0,new Array(),"");
  //lonlatLine = removeBlanks(lonlats[i].replace(/\s*/gi,",").split(","));
  nameLine = names[i];
  ids[nameLine] = i;
  popLine = populations[i];
  if (0 == i) {
    //console.log("dists: " + dists[i]);
    console.log("distLine: " + distLine);
    console.log("lonlatLine: " + lonlatLine);
  }

  cities[i] = {
    name: nameLine,population: popLine,
    lat: ((1 * lonlatLine[0]) + ((1 * lonlatLine[1])/60) + (1*lonlatLine[2])/3600),
    lon: ((1 * lonlatLine[4]) + ((1 * lonlatLine[5])/60) + (1 * lonlatLine[6])/3600),
    rd: distLine
  };
}


var city;
// now, process each of the cities and calculate 5 nearest other cities
for (i = 0;i < 128;i++) {
  city = cities[i];
  city.distances = {};
  for (var j = 0;j < 128;j++) {
    city.distances[cities[j].name] = city.rd[j];
  }
  delete city.rd;
}

for (i = 0;i < 128;i++) {
  //console.log("----------");
  var minDists = new Array();
  city = cities[i];
  for (var to in city.distances) {
    var dist = 1 * city.distances[to];
    if (minDists.length < 5) {
      //console.log("Adding initial distance: city: " + to + " dist: " + dist);
      minDists.push({name: to,dist: dist});
    } else {
      var found = false;
      for (var md = 0;!found && md < 5;md++) {
        if (0 != dist && (0 == minDists[md].dist || dist < minDists[md].dist)) {
          //console.log("Replacing position " + md + " (city: " + minDists[md].name + ", dist: " + minDists[md].dist + ") with city: " + to + " with dist: " + dist);
          minDists[md] = {name: to, dist: dist};
          found = true;
        }
      }
    }
  }
  city.distances = {};
  for (var md = 0;md < minDists.length;md ++) {
    city.distances[minDists[md].name] = minDists[md].dist;
  }
}

// print first city to console to test
console.log("First city:-");
console.log(JSON.stringify(cities[0]));


// generate RDF N3 triples for each city
var rdf = "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n";
rdf += "@prefix gq: <http://marklogic.com/semantics/graphqueries#> .\n";
for (var i = 0;i < 128;i++) {
  city = cities[i];
  var id = "gq:city" + i + "";
  rdf += id + " rdf:type gq:city . " + id + " gq:name \"" + city.name + "\" . " + id + " gq:lon " + city.lon + " . " + id + " gq:lat " + city.lat + " . \n";
  rdf += id + " gq:id " + i + " .\n";
  for (var c in city.distances) {
    rdf += id + " gq:near gq:city" + ids[c] + " .\n";
    rdf += "gq:city" + ids[c] + " gq:near " + id + " .\n";
    rdf += "gq:city" + i + " gq:distanceTo_" + ids[c] + " " + city.distances[c] + " .\n";
    rdf += "gq:city" + ids[c] + " gq:distanceTo_" + i + " " + city.distances[c] + " .\n";
  }
}
//console.log(rdf);

// output to a file
fs.writeFileSync("../data/rdf/cities.ttl",rdf,"utf-8");

// end

process.exit(0);
