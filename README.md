# Configured Maven projects for Defects4J 1.2 programs

Sometimes we need a configured Defects4J repository to facillitate the use of maven plugins. https://github.com/lx0704/Defects4J-Maven is configured for that purpose (please read that README first). However, part of the repo (Defects4J 1.2 dataset) was configured too earlier that some source files have been outdated. So this repo reconfigured the programs to mitigate the gap. The source files are consistent with the latest (and stable) version of the Defects4J programs. The "Repository" contains most of the required dependencies (directly copied from lx0704 version). Please copy all the dependencies to the .m2 folder.

If you still find some dependencies missing (or connection to repository server timing out), please first check the local folders, e.g., "lib", to obtain the required jar file, and use "mvn install-file" command to install the jar file to local.

If you find some programs showing different result with defects4j command, please report the issues.

## Changes for Uniapr

In order to make the profiler of uniapr has the same test execution result as the defects4j, some changes need to be made. The ideal case is that for all defects4j projects compiled by defects4j, we can directly run unipar by add corresponding pom.xml files. Most projects can work in this way, but for some projects, the source code needs to be changed.

### Closure
1. Change `mockito:mockito:1.0` to `org.mockito:mockito-all:1.10.19` in pom.xml
2. Change `com.google.protobuf:protobuf-java` to the local jar lib/protobuf-java.jar
3. Closure-106 needs maven to compile.

### Lang
The source code must be changed so that the tests will not affect the tests executed later. Defects4j seems to executed each test class in seperate JVM so it does not suffer from this.
```java
public class StandardToStringStyleTest extends TestCase {
    ...
    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
    -   ToStringBuilder.setDefaultStyle(STYLE);
    +   ToStringBuilder.setDefaultStyle(DEFAULT_STYLE);
    }
    ...
}
```

### Math
The source code must be changed so that the tests will not affect the tests executed later.
```java
public class UniformCrossoverTest {
    ...
-   @BeforeClass
-   public static void setUpBeforeClass() {
+   @Before
+   public void setUpBeforeClass() {
+       p1.clear();
+       p2.clear();
        for (int i = 0; i < LEN; i++) {
            p1.add(0);
            p2.add(1);
        }
    }
    ...
}
```

### Mockito
**Please use defects4j to validate the patches for Mockito-5 (it requires the validating JVM has not loaded the class junit.framework.ComparisonFailure)**

Change `org.easytesting:fest-assert:1.4` to other version depend on what is in the lib

### Time
Remove two tests that affects by previsouly executed tests (executing tests in the same order as defects4j, it seems the cache is messed by previous tests) and can't be easily fixed. 