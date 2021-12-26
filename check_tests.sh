cp -r Repository/* ~/.m2/repository/
pwd=`pwd`

check_has_fail(){
    if ! grep -q FAIL $1; then
        echo Error: No failed test in $1!!!
    fi
}

check_empty_and_delete(){
    if [ ! -s $1 ]; then
        echo Error: $1 is empty!!!
        rm $1
    fi
}

file_contains_string(){
    if grep -q $2 $1; then
        true
    else 
        false
    fi
}

parse_mvn_test_list(){
    find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase name=\"\(.*\)\" classname=\"\(.*\)\" time=\"\(.*\)\".*/\2#\1 PASS/p" | sort | uniq > mvnTestList
    # different version of surefire may have different format
    if [ ! -s mvnTestList ]; then
        find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase classname=\"\(.*\)\" name=\"\(.*\)\" time=\"\(.*\)\".*/\1#\2 PASS/p" | sort | uniq > mvnTestList
    fi
    if [ ! -s mvnTestList ]; then
        find -name "TEST-*.xml" -exec grep testcase {} + | sed -n "s/.*testcase time=\".*\" classname=\"\(.*\)\" name=\"\(.*\)\".*/\1#\2 PASS/p" | sort | uniq > mvnTestList
    fi
}

parse_mvn_failed_tests(){
    cat mvn-test.log | sed -n 's/\(.*\)(\(.*\))  Time elapsed: .* sec  <<< \(FAILURE\|ERROR\)!/\2#\1/p' > mvnFailedTests
    if [ ! -s mvnFailedTests ];then
         sed -n 's/  \(.*\)(\(.*\))/\2#\1/p' mvn-test.log > mvnFailedTests
    fi
    # match for Mockito-38, it seems to use a different maven version 
    if [ ! -s mvnFailedTests ];then
         sed -n 's/\[ERROR\] \(.*\)(\(.*\))  Time elapsed: .* s  <<< \(FAILURE\|ERROR\)!/\2#\1/p' mvn-test.log > mvnFailedTests
    fi
    for line in `cat mvnFailedTests`; do
         sed -i "s/$line PASS/$line FAIL/" mvnTestList
    done
}

# in case some tests get initializationError
handle_mvn_initError(){
    echo -n > mvnInitErrorTests
    sed -n 's/initializationError(\(.*\))  Time elapsed: .* sec  <<< \(FAILURE\|ERROR\)!/\1/p' mvn-test.log | sort | uniq >> mvnInitErrorTests
    for line in `cat mvnInitErrorTests`;do
        sed -i "s/$line#initializationError FAIL/$line INITIALIZATION_ERROR/" mvnTestList
    done
    if [ ! -s mvnInitErrorTests ];then
        sed -n 's/.*) initializationError(\(.*\))/\1/p' mvn-test.log | sort | uniq >> mvnInitErrorTests
        for line in `cat mvnInitErrorTests`;do
            echo $line INITIALIZATION_ERROR >> mvnTestList
        done
    fi
}

for proj in `ls Projects`; do
    for idx in `ls Projects/$proj`; do
        
        mkdir -p TestLists/$proj/$idx       
        echo Processing $proj-$idx...
        
        if [ ! -f TestLists/$proj/$idx/d4jTestList ]; then
            # collect d4j test list
            echo Collecting defects4j test list for $proj-$idx...
            if [ ! -d D4J_Proj/$proj/$idx ]; then
                mkdir -p D4J_Proj/$proj
                defects4j checkout -p $proj -v "$idx"b -w D4J_Proj/$proj/$idx  2>&1
                cd D4J_Proj/$proj/$idx && defects4j test > d4j-test.log
                sed -n -i 's/  - \(.*\)::\(.*\)/\1#\2/p' d4j-test.log
            else 
                cd D4J_Proj/$proj/$idx
            fi
            # Note that there can be duplicated lines in all_tests file (e.g., Chart-12)!
            # use uniq after sort !!
            cat all_tests |  sed -n 's/\(.*\)(\(.*\))/\2#\1 PASS/p' | sort | uniq > d4jTestList
            for line in `cat d4j-test.log`; do
                sed -i "s/$line PASS/$line FAIL/" d4jTestList
            done
            cd $pwd && cp D4J_Proj/$proj/$idx/d4jTestList TestLists/$proj/$idx/d4jTestList
            check_has_fail TestLists/$proj/$idx/d4jTestList
        else 
            echo Defects4J test list for $proj-$idx alreadly exists!
        fi
        check_empty_and_delete TestLists/$proj/$idx/d4jTestList
        

        if [ ! -f TestLists/$proj/$idx/mvnTestList ]; then
            # collect mvn test list
            echo Collecting maven test list...
            cd Projects/$proj/$idx  
            if [ ! -f mvn-test.log ] || [[ ! $(find -name "TEST-*.xml")  ]]  ||  file_contains_string mvn-test.log "java.lang.OutOfMemoryError:"; then
                mvn -Dhttps.protocols=TLSv1.2 -DargLine="-Xmx4096m"  clean test -l mvn-test.log
            fi
            parse_mvn_test_list
            parse_mvn_failed_tests
            handle_mvn_initError
            cd $pwd && cp Projects/$proj/$idx/mvnTestList TestLists/$proj/$idx/mvnTestList
            check_has_fail TestLists/$proj/$idx/mvnTestList
        else
            echo Maven test list for $proj-$idx alreadly exists!
        fi
        check_empty_and_delete TestLists/$proj/$idx/mvnTestList


        # clean up
        #rm Projects/$proj/$idx/mvn-test.log Projects/$proj/$idx/mvnFailedTests 

        echo

    done
done
        
