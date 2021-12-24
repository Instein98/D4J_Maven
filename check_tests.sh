cp -r Repository/* ~/.m2/repository/
pwd=`pwd`

function check_has_fail(){
    if ! grep -q FAIL $1; then
        >&2 echo Error: No failed test in $1!!!
    fi
}

function check_empty_and_delete(){
    if [ ! -s $1 ]; then
        >&2 echo Error: $1 is empty!!!
        rm $1
    fi
}

for proj in `ls Projects`; do
    for idx in `ls Projects/$proj`; do
        
        mkdir -p TestLists/$proj/$idx       
        echo Processing $proj-$idx...
        
        if [ ! -f TestLists/$proj/$idx/d4jTestList ]; then
            # collect d4j test list
            echo Collecting defects4j test list for $proj-$idx...
            defects4j checkout -p $proj -v "$idx"b -w $proj-$idx > /dev/null 2>&1
            cd $proj-$idx && defects4j test > d4j-test.log
            sed -n -i 's/  - \(.*\)::\(.*\)/\1#\2/p' d4j-test.log
            cd $pwd && cat $proj-$idx/all_tests | sed -n 's/\(.*\)(\(.*\))/\2#\1 PASS/p' | sort > TestLists/$proj/$idx/d4jTestList
            for line in `cat $proj-$idx/d4j-test.log`; do
                sed -i "s/$line PASS/$line FAIL/" TestLists/$proj/$idx/d4jTestList
            done
            check_has_fail TestLists/$proj/$idx/d4jTestList
        else 
            echo Defects4J test list for $proj-$idx alreadly exists!
        fi
        check_empty_and_delete TestLists/$proj/$idx/d4jTestList
        

        if [ ! -f TestLists/$proj/$idx/mvnTestList ]; then
            # collect mvn test list
            echo Collecting maven test list...
            cd Projects/$proj/$idx && mvn clean test -l mvn-test.log
            find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase name=\"\(.*\)\" classname=\"\(.*\)\" time=\"\(.*\)\".*/\2#\1 PASS/p" | sort > $pwd/TestLists/$proj/$idx/mvnTestList
            # different version of surefire may have different format
            if [ ! -s TestLists/$proj/$idx/mvnTestList ]; then
                find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase classname=\"\(.*\)\" name=\"\(.*\)\" time=\"\(.*\)\".*/\2#\1 PASS/p" | sort > $pwd/TestLists/$proj/$idx/mvnTestList
            fi
            cat mvn-test.log | sed -n 's/\(.*\)(\(.*\))  Time elapsed: .* sec  <<< FAILURE!/\2#\1/p' > mvnFailedTests
            for line in `cat mvnFailedTests`; do
                sed -i "s/$line PASS/$line FAIL/" $pwd/TestLists/$proj/$idx/mvnTestList
            done
            check_has_fail $pwd/TestLists/$proj/$idx/mvnTestList
            cd $pwd
        else
            echo Maven test list for $proj-$idx alreadly exists!
        fi
        check_empty_and_delete TestLists/$proj/$idx/mvnTestList


        # clean up
        rm -rf $proj-$idx  # remove d4j subject
        rm Projects/$proj/$idx/mvn-test.log Projects/$proj/$idx/mvnFailedTests 

        echo

    done
done
        
