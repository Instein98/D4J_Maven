cp -r Repository/* ~/.m2/repository/

pwd=`pwd`
for proj in `ls Projects`; do
    for idx in `ls Projects/$proj`; do
        mkdir -p TestLists/$proj/$idx       
        echo Processing $proj-$idx...
        
        if [ ! -f TestLists/$proj/$idx/d4jTestList ]; then
            # collect d4j test list
            echo Collecting defects4j test list for $proj-$idx...
            defects4j checkout -p $proj -v "$idx"b -w $proj-$idx > /dev/null 2>&1
            cd $proj-$idx && defects4j test > /dev/null 2>&1
            cd $pwd && cat $proj-$idx/all_tests | sed -n 's/\(.*\)(\(.*\))/\2#\1/p' | sort > TestLists/$proj/$idx/d4jTestList
        else 
            echo Defects4J test list for $proj-$idx alreadly exists!
        fi
        if [ ! -s TestLists/$proj/$idx/d4jTestList ]; then
            >&2 echo Error: TestLists/$proj/$idx/d4jTestList is empty!!!
            rm TestLists/$proj/$idx/d4jTestList
        fi
        rm -rf $proj-$idx
        

        if [ ! -f TestLists/$proj/$idx/mvnTestList ]; then
            # collect mvn test list
            echo Collecting maven test list...
            cd Projects/$proj/$idx && mvn clean test -l mvn-test.log
            find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase name=\"\(.*\)\" classname=\"\(.*\)\" time=\"\(.*\)\".*/\2#\1/p" | sort > $pwd/TestLists/$proj/$idx/mvnTestList
            if [ ! -s TestLists/$proj/$idx/mvnTestList ]; then
                find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase classname=\"\(.*\)\" name=\"\(.*\)\" time=\"\(.*\)\".*/\2#\1/p" | sort > $pwd/TestLists/$proj/$idx/mvnTestList
            fi
            cd $pwd
        else
            echo Maven test list for $proj-$idx alreadly exists!
        fi
        if [ ! -s TestLists/$proj/$idx/mvnTestList ]; then
            >&2 echo Error: TestLists/$proj/$idx/mvnTestList is empty!!!
            rm TestLists/$proj/$idx/mvnTestList
        fi
 

        if [ ! -f TestLists/$proj/$idx/praprTestList ]; then
            # collect prapr test list (when prapr is collecting test coverage)
            echo Collecting prapr test list...
            cd Projects/$proj/$idx && mvn org.mudebug:prapr-plugin:COV:prapr -l prapr-cov.log
            sed -E -i 's/^H\(\\\|\/\||\|-\)//g' prapr-cov.log  # remove backspace and | / - \ 
            cat prapr-cov.log | sed -n 's/.*TestStart: .*\.\(.*\)(\(.*\))/\2#\1/p'| uniq | sort > $pwd/TestLists/$proj/$idx/praprTestList
            cd $pwd 
        else
            echo PraPR test list for $proj-$idx alreadly exists!
        fi
        if [ ! -s TestLists/$proj/$idx/praprTestList ]; then
            >&2 echo Error: TestLists/$proj/$idx/praprTestList is empty!!!
            rm TestLists/$proj/$idx/praprTestList
        fi
        

        echo
        break
    done
done
        
