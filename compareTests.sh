#cd TestLists
for d in TestLists/*/*; do
    echo ===== $d =====
    diff -s $d/d4jTestList $d/mvnTestList
    #diff <(cut -f1 -d\# $d/d* | sort -u) <(cut -f1 -d\# $d/m* | sort -u)
    echo
done
