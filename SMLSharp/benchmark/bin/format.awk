BEGIN {
    SUBSEP = ":"
    benchNo = 1
    "date" | getline now
}

function append(key, value) {
    if (bench[key]) bench[key] = bench[key] "\n"
    bench[key] = bench[key] value
}

/^==/ {
    benchNo += 1
}
/^[A-Za-z0-9_.():]*:/ {
    value = substr($0, length($1) + 1)
    sub("^ *", "", value)
    sub(":$", "", $1)
    append(benchNo ":" $1, value)
}

# bench[<benchNo>,"name"]
# bench[<benchNo>,"date"]
# bench[<benchNo>,"numResults"]
# bench[<benchNo>,"option","options"]
# bench[<benchNo>,"option",<optionName>]
# bench[<benchNo>,"message"]
# bench[<benchNo>,"result",<resultNo>,"sourcePath"]
# bench[<benchNo>,"result",<resultNo>,"compileTime"]
# bench[<benchNo>,"result",<resultNo>,"compileProfile","profiles"]
# bench[<benchNo>,"result",<resultNo>,"compileProfile",<profileName>]
# bench[<benchNo>,"result",<resultNo>,"exitStatus"]
# bench[<benchNo>,"result",<resultNo>,"exceptions"]
# bench[<benchNo>,"result",<resultNo>,"compileOutput"]
# bench[<benchNo>,"result",<resultNo>,"executeOutput"]

function h(str) {
    gsub("&", "\\&amp;", str)
    gsub("<", "\\&lt;", str)
    gsub(">", "\\&gt;", str)
    gsub("\"", "\\&quot;", str)
    return str
}

function resultName(benchNo, resultNo) {
    if (bench[benchNo, "name"] && bench[benchNo, "numResults"] == 1)
        return bench[benchNo, "name"]
    else
        return bench[benchNo, "name"] ":" resultNo
}

END {
    stripe[0] = "stripe0"
    stripe[1] = "stripe1"

    #for (i in bench) {
    #    print "== " i
    #    print bench[i]
    #}

    numBench = 0
    for (i in bench) {
        split(i, a, SUBSEP)
        if (numBench < a[1]) numBench = a[1]
    }

    numProfiles = 0
    for (i = 1; i <= numBench; i++) {
        for (j = 1; j <= bench[i,"numResults"]; j++) {
            split(bench[i,"result",j,"compileProfile","keys"], profiles, "\n")
            for (k = 1; k in profiles; k++) {
                name = profiles[k]
                if (!profileMap[name]) {
                    profileMap[name] = ++numProfiles
                    profiles[numProfiles] = name
                }
            }
        }
    }

    for (prof in profileMap) {
        profiles[profileMap[prof]] = prof
    }

    print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">"
    print "<html>"
    print "<head>"
    print "<style type=\"text/css\">"
    print "<!--"
    print "body {font-size:9pt}"
    print "table {border-color:#ccc;border-width:1px;padding:0;border-collapse:collapse}"
    print "th,tr,td{border-style:solid;border-color:#ccc;border-width:1px;padding:.3em 2ex}"
    print "th,td {text-align: center}"
    print "th {background-color: #f8ffff}"
    print "thead th {background-color: #eef}"
    print "table.large th,table.large td {font-size: x-small;padding: 2px}"
    print "strong.fatal {color: red;font-weight:bold}"
    print "em.yes {color: red;font-style:normal}"
    print "em.no {color: blue;font-style:normal}"
    print "pre {width: 95%; overflow: auto; background-color: #eee;padding:4px;border:1px solid #ccc}"
    print "-->"
    print "</style>"
    print "</head>"
    print "<body>"

    print "<h1>Benchmark Results</h1>"
    print "<p>Created on " h(now) "</p>"

    print "<h2>Summary</h2>"

    print "<h3>Time</h3>"
    print "<table>"
    print "<thead>"
    print "<tr>"
    print "<th>Benchmark Result</th>"
    print "<th>Compilation Time (sys / usr / real)</th>"
    print "<th>Execution Time (sys / usr / real)</th>"
    print "</tr>"
    print "</thead>"
    lineno = 0
    for (i = 1; i <= numBench; i++) {
        for (j = 1; j <= bench[i,"numResults"]; j++) {
            name = resultName(i, j)
            status = bench[i,"result",j,"exitStatus"]
            comp = bench[i,"result",j,"compileTime"]
            exec = bench[i,"result",j,"executionTime"]
            print "<tr class=\"" stripe[lineno % 2] "\">"
            print "<th><a href=\"#b" i "-" j "\">" h(name) "</a></th>"
            if (status != "0")
                print "<td colspan=\"2\"><strong class=\"fatal\">failed</strong></td>"
            else
                print "<td>" h(comp) "</td><td>" h(exec) "</td>"
            print "</tr>"
            lineno++
        }
    }
    print "</table>"

    print "<h3>Compiler Profile</h3>"
    print "<table class=\"large\">"
    print "<thead>"
    print "<tr><th>timer</th>"
    for (i = 1; i <= numBench; i++) {
        for (j = 1; j <= bench[i,"numResults"]; j++) {
            name = resultName(i, j)
            print "<th><a href=\"#b" i "-" j "\">" h(name) "</a></th>"
        }
    }
    print "</tr>"
    print "</thead>"
    lineno = 0
    for (p = 1; p < numProfiles; p++) {
        prof = profiles[p]
        print "<tr class=\"" stripe[lineno % 2] "\">"
        print "<th>" h(prof) "</th>"
        for (i = 1; i <= numBench; i++) {
            for (j = 1; j <= bench[i,"numResults"]; j++) {
                name = resultName(i, j)
                time = bench[i,"result",j,"compileProfile",prof]
                if (!time) time = "-"
                print "<td>" h(time) "</td>"
            }
        }
        print "</tr>"
        lineno++
    }
    print "</table>"

    for (i = 1; i <= numBench; i++) {
        print "<hr/>"
        print "<h2 id=\"b" i "\">Benchmark " i " - " h(bench[i,"name"]) "</h2>"

        print "<p>Date: " h(bench[i,"date"]) "</p>"
        print "<p>Options:</p>"
        print "<table class=\"large\">"
        lineno = 0
        split(bench[i,"option","keys"], options, "\n")
        for (j = 1; j in options; j++) { 
            print "<tr class=\"" stripe[lineno % 2] "\">"
            key = options[j]
            value = bench[i,"option",key]
            print "<th>" h(key) "</th>"
            if (value == "yes")
                print "<td><em class=\"yes\">yes</em></td>"
            else if (value == "no")
                print "<td><em class=\"no\">no</em></td>"
            else
                print "<td>" h(value) "</td>"
            print "</tr>"
            lineno++
        }
        print "</table>"

        for (j = 1; j <= bench[i,"numResults"]; j++) {
            name = resultName(i, j)
            print "<h3 id=\"b" i "-" j "\">Benchmark " i " Result " j " - " h(name) "</h3>"

            print "<table>"
            print "<tr class=\"stripe0\">"
            print "<th>Source Path</th>"
            print "<td>" h(bench[i,"result",j,"sourcePath"]) "</td>"
            print "</tr>"

            comp = bench[i,"result",j,"compileTime"]
            print "<tr class=\"stripe1\">"
            print "<th>Compilation Time</th>"
            if (comp)
                print "<td>" h(comp) " (sys / usr / real)</td>"
            else
                print "<td>-</td>"
            print "</tr>"

            exec = bench[i,"result",j,"executionTime"]
            print "<tr class=\"stripe0\">"
            print "<th>Execution Time</th>"
            if (exec)
                print "<td>" h(exec) " (sys / usr / real)</td>"
            else
                print "<td>-</td>"
            print "</tr>"
            
            print "<tr class=\"stripe1\">"
            print "<th>Exit Status</th>"
            if (bench[i,"result",j,"exitStatus"] == "0")
                print "<td>0</td>"
            else
                print "<td><strong class=\"fatal\">" h(bench[i,"result",j,"exitStatus"]) "</strong></td>"
            print "</tr>"
            print "</table>"

            print "<dl>"
            if ((i,"result",j,"message") in bench) {
                print "<dt>Message:</dt>"
                print "<dd><pre>"
                print h(bench[i,"result",j,"message"])
                print "</pre></dd>"
            }

            print "<dt>Exceptions:</dt>"
            if ((i,"result",j,"exceptions") in bench) {
                print "<dd><pre>"
                print h(bench[i,"result",j,"exceptions"])
                print "</pre></dd>"
            } else {
                print "<dd>no exception.</dd>"
            }

            print "<dt>Compiler Output:</dt>"
            if ((i,"result",j,"compileOutput") in bench) {
                print "<dd><pre>"
                print h(bench[i,"result",j,"compileOutput"])
                print "</pre></dd>"
            } else {
                print "<dd>no output.</dd>"
            }

            print "<dt>Program Output:</dt>"
            if ((i,"result",j,"executeOutput") in bench) {
                print "<dd><pre>"
                print h(bench[i,"result",j,"executeOutput"])
                print "</pre></dd>"
            } else {
                print "<dd>no output.</dd>"
            }

            print "</dl>"
        }
    }

    print "</body></html>"
}
