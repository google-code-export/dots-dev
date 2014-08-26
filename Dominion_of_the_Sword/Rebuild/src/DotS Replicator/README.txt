 ==================================================
| Dominion of the Sword Script Replication Utility |
|               Version 3.0.0 (r796)               |
|                    2011/01/07                    |
 ==================================================

I.    INTRODUCTION
II.   USAGE
III.  WRITING SIMPLE REPLICATION MACROS
IV.   WRITING ADVANCED REPLICATION MACROS
V.    GLOBAL VARIABLES
VI.   USING FORMATTING MODES
VII.  WRITING CONFIGURATION FILES
VIII. THE DEFAULT SETS

I.   DotS Replicator is a utility that can automatically duplicate 
     segments of code over set of arguments. Duplication can be nested 
     over multiple variables, tracked with a counter, and modified with 
     various criteria.

II.  DotS Automap is invoked on the command line: 

         >  dots_replicator [options] input.txt output.txt [config.yml]

     input is an text file containing DotS Replicator macros. output is 
     the destination for the output. config.yml is an input file 
     containing datasets and program options. [options] is any 
     combination of the following:

         -c [ --comment] arg (=';')  The string that indicates the
                                     beginning of a line comment.

         -p [ --prefix] arg (='!')   A string that indicates that
                                     the following comment line is
                                     a DotS Replicator macro.

         -i [ --input-encoding] arg  The encoding to use when reading 
                                     the input file. (Autodetected by 
                                     default.)

         -o [ --output-encoding] arg The encoding to use when writing 
                                     the output file. (UTF-8 by 
                                     default.)

         -g [ --no-globals]          Disable the substitution of 
                                     globals. This may give a slight 
                                     performance boost.

         -s [ --prefix-sequence] arg Use the given single character
                                     prefixes in sequence.

III. DotS Replicator reads a text file for macros. It will alter the 
     file according to the macros and write the altered version to a 
     new file.

     The most basic macro is the repeat macro. It copies the given text 
     a set number of times:

        ;!repeat 5 times
          add_money 5000
        ;!end

     As can be seen in the example, it is recommended that macros are 
     written on comment lines. This allows the file to be run without 
     having been processed by DotS Replicator. A command prefix is also 
     used to distinguish comments containing macros from normal 
     comments. In this example the default prefix is used, an 
     exclamation point (!). (Comment and command prefixes are not 
     necessary if the --comment and --prefix options are set to '')

     The next part of the statement is the command itself `repeat 5 
     times'. After the command line comes the block of text to be 
     replicated. This block can span as many lines as desired. The 
     block command `end' closes the block of text.

     This macro will result in the following output:

          add_money 5000

          add_money 5000

          add_money 5000

          add_money 5000

          add_money 5000

     The repeat macro is of limited use. (Why not just copy the line 
     five times manually or instead write `add_money 25000'?) 
     Replication macros are much more useful when they operate on 
     sets.

     Sets are simply lists of text. Here is an example:

        ;!declare factions as set
        ;  !england
        ;  !france
        ;  !scotland
        ;  !spain
        ;!end

     Sets can also be defined in an external file for reuse by multiple 
     scripts or to store items that span more than one line. See 
     WRITING CONFIGURATION FILES for more information.

     The main user of sets is the for each loop. Here is an example of 
     a for each loop:

        ;!for each faction in all factions
        monitor_event FactionTurnEnd FactionType {faction}
          console command add_money {faction}, 500
        end_monitor
        ;!end

     The first part of the command, `for each', is the command name. 
     The next part, `faction in all factions' are the instructions for 
     the command. The `in all factions' portion tells the for each 
     macro to operate on all elements of the `factions' set. The 
     `faction' section tells us that the iterator for this for each 
     loop is `factions'. Therefore, each time the code is replicated 
     the current faction will be substituted into the text block 
     wherever marked. These positions are marked by enclosing the 
     iterator name within braces ({}) in various places in the text 
     block. Here is what the above code will produce with the 
     previously given definition of the factions set.

        monitor_event FactionTurnEnd FactionType england
          console command add_money england, 500
        end_monitor

        monitor_event FactionTurnEnd FactionType france
          console command add_money france, 500
        end_monitor

        monitor_event FactionTurnEnd FactionType scotland
          console command add_money scotland, 500
        end_monitor

        monitor_event FactionTurnEnd FactionType spain
          console command add_money spain, 500
        end_monitor

     Now the true power of DotS Replicator is revealed!

     Sometimes, it will be necessary to iterate over only some elements 
     of a set. The for loop provides two ways to do this: inclusion and 
     exclusion. Here is an example:

        ;!for each faction in all factions except slave papal_states
        monitor_event FactionTurnEnd FactionType {faction}
          add_money {faction}, 500
        end_monitor
        ;!end

     In this example, the set is modified by both the `all' keyword and 
     the `except' keyword. The `all' keyword first tells DotS 
     Replicator to look at all elements of the set. The `except' 
     keyword then tells DotS replicator to ignore some of those 
     elements. In this example, the block will be replicated once for 
     all factions except the rebels (slave) and the Papal States.

     Instead of selectively excluding elements, it is also possible to 
     selectively include them:

        ;!for each faction in factions slave papal_states
        monitor_event FactionTurnEnd FactionType {faction}
          add_money {faction}, 500
        end_monitor
        ;!end

     In this example, the `all' keyword is omitted. This tells DotS 
     replicator to start by looking at none of the elements instead of 
     starting with all of them. Elements are then selectively included 
     by listing them after the set name. Note that no `include' keyword 
     is necessary. (Or allowed) This sample will replicate the code 
     once for the rebels (slave) and the Papal States and for no other 
     factions.

     Macros can be nested for layers of replication. For example, to 
     model diplomacy, we would need one repetition for each possible 
     combination of two factions. This can be accomplished with two 
     nested for loops:

        ;!for each faction1 in all factions except slave
          ;!for each faction2 in all factions except slave
          monitor_event FactionTurnEnd TrueCondition
            ;...
            ;diplomacy code here
            add_money {faction1}, 500
            add_money {faction2}, 500
            ;...
          end_monitor
          ;!end
        ;!end

     There is no limit to the levels of nesting. Just ensure that only 
     one output variable with a given name exists at any point. If two 
     or more output variables have the same name at a given point, 
     replication may become erratic.

IV.  DotS Replicator also offers numerical constructs. One example is 
     the for range macro. The following is an example of the for range 
     macro:

        ;!for each amount in range 0 to 3000 increment 1000
          add_money {amount}
        ;!end

     The increment value is optional and defaults to one if not 
     specified.

     The above code results in the following output:

          add_money 0

          add_money 1000

          add_money 2000

          add_money 3000

     Keep in mind that the increment value can also be negative:

        ;!for each amount in range 3000 to 0 increment -1000
          add_money {amount}
        ;!end

     This would result in the same output as before, but flipped.

     Loops are not the only construct available with DotS Replicator; 
     counting blocks can also be used to track the number of 
     iterations:

        ;!for each faction in factions
          ;!declare count as counter value 0 increment 1000
          monitor_event FactionTurnStart FactionType {faction}
            add_money {faction}, {count}
          end_monitor
          ;!end
        ;!end

     The above code will grant each faction money every turn. The first 
     faction in the factions set will receive zero florins and each 
     subsequent faction will receive 1000 florins more than the 
     previous one.

     Counters look similar to for loops, but they are not loops. 
     Because they do not take sets as parameters, they do not have 
     anything to loop over. Instead, counters have to be nested inside 
     for loops. Each time the for loop iterates, the counter will also 
     iterate and will increment. `value' is followed by an integer, the 
     starting value of the counter. `increment' is followed by another 
     integer, the amount by which the counter is increased for each 
     repetition. `value' and `increment' are both optional, but when 
     they appear together, they must appear in the order shown. The 
     default starting value is zero and the default increment value is 
     one.

     What would have happened if a for range block was nested inside 
     instead of a counter declaration?

        ;!for each faction in factions
          ;!for each count in range 0 to 3000 increment 1000
          monitor_event FactionTurnStart FactionType {faction}
            add_money {faction}, {count}
          end_monitor
          ;!end
        ;!end

     This would result in a completely different output. Four monitors 
     would be generated for each faction, one with add_money 0, one 
     with add_money 1000, one with add_money 2000, and one with 
     add_money 3000.

     There is a version of the counter statement for textual sets. The 
     `with above' statement is similar to the counter statement in that 
     it depends on its parent to cause it to loop over its data. 
     However, like for each, with above operates on elements from a set 
     of data:

        ;!for each faction in all factions
          ;!with above each capital in all capitals
          monitor_event SettlementTurnEnd FactionType {faction}
          and SettlementName {capital}
            ;...
          end_monitor
          ;!end
        ;!end

     The above code WILL NOT be replicated for all capitals. Instead, 
     for each iteration of the factions for each loop, the next capital 
     will be taken from the settlement set. So if there are 31 
     factions, than only the first 31 settlements will be used. For 
     example, if the sets were defined as follows

        factions          capitals
        --------          --------
        England           London
        France            Paris
                          Venice

     the following code would be generated:

         monitor_event SettlementTurnEnd FactionType England
         and SettlementName London
           ;...
         end_monitor

         monitor_event SettlementTurnEnd FactionType France
         and SettlementName Paris
           ;...
         end_monitor

     No code would have been generated for Venice because the outer 
     factions loop would have already exhausted all of the items in its 
     set and terminated.

     The with above statement is to be used when it is necessary to 
     iterate over two data sets simultaneously rather than having 
     nested loops (which would iterate over all possible combinations 
     of the data sets).

     Another construct that is similar to `declare... counter' or `with 
     above' is the `if' statement. The if statement is similar to `with
     above except that it takes boolean values instead of string 
     values. Like with above, if will iterate through a set along with 
     a parent loop. Unlike with above, it will only write its content 
     if the current item evaluates to true. This is best illustrated 
     through an example. Consider a diplomacy script that uses the 
     following sets:

        factions          is_catholic
        --------          --------
        england           true
        egypt             false

     If this code was used

       ;!for each faction in all factions except papal_states slave
         monitor_event GeneralAssaultsGeneral FactionType {faction}
         and TargetFactionType papal_states
           ;...
           ;!if is_catholic
           ;Do something specific to Catholic factions
           ;!end
           ;...
         end_monitor
       ;!end

     Catholic-specific code would be generated for England, but not for
     Egypt:

         monitor_event GeneralAssaultsGeneral FactionType england
         and TargetFactionType papal_states
           ;...
           ;Do something specific to Catholic factions
           ;...
         end_monitor

         monitor_event GeneralAssaultsGeneral FactionType egpyt
         and TargetFactionType papal_states
           ;...
           ;...
         end_monitor

V.   DotS Replicator macros are typically descriptive rather than 
     stateful. In other words, the result of running DotS Replicator on 
     a given file depends mostly on the datasets that are provided in 
     the configuration file rather than on the macros in the input 
     file. Usually, this seperation of form from content is the desired 
     behavior; it is useful to be able to produce multiple output files 
     from a single input file. However, there are also some cases in 
     which it can be useful to represent data and state within the 
     input file rather than within the output file. DotS Replicator has 
     some features for these cases.

     The simplest way to store data in an input file is to use a global 
     variable. The value of a global variable can be defined with a 
     `set global' statement:

       ;!set global $author
       Azim
       ;!end

     As can be seen in the example above, A global variable does not 
     have to be declared before given a value. Global variables are 
     also mutable; they can be given multiple different values by using 
     multiple set statements.

     Once given a value, a global variable can then be written into the 
     output using syntax that is very similar to that used for 
     iterators. The following code

       ; This script was written by {$author}

     would yield this output:

       ; This script was written by Azim

     Some globals, such as $date, $time, $file, and $path, are defined 
     automatically.

     Globals are normally substituted at the end of processing, but 
     they can be substituted early using the `glob' statement:

       ;!glob
       ; This script was written by {$author}
       ;!end

     Note that globals will still be substituted at the end of 
     processing.

     The glob statement can also elect to substitute only some 
     globals:

       ;!glob all globals except $author
       ; This script was written by {$author}
       ;!end

     In addition to globals, DotS Replicator allows for parameterized 
     routines. For example

       ;!declare add_money_to_faction as macro on faction amount
       ;  !add_money {faction} {amount}
       ;!end

       ;!write add_money_to_faction with england 5000

     This will generate the following code:

       add_money england 5000

VI.  The spacing between replicated blocks can be controlled with a set 
     of three formatting operators: +, -, and =. By default, the 
     formatting specifier is +. The formatting mode can be changed by 
     inserting a formatting specifier before a macro command.

     The + operator leaves an additional line break after each 
     replication:

        ;!+repeat 3 times
          add_money 5000
        ;!end

     Results in:

          add_money 5000

          add_money 5000

          add_money 5000

     The - operator leaves no additional line break between blocks:

        ;!-repeat 3 times
          add_money 5000
        ;!end

     Results in:

          add_money 5000
          add_money 5000
          add_money 5000

     The = operator (think of it as double minus) leaves a space 
     between each repetition:

        ;!=repeat 3 times
          add_money 5000
        ;!end

     Results in:

          add_money 5000 add_money 5000 add_money 5000

VII. DotS Replicator can load sets and options from an external 
     configuration file. By default, the program loads with the 
     default.yaml configuration. In this configuration, the settlements 
     set contains the names of all M2TW vanilla campaign settlements, 
     the factions set contains the names of all M2TW vanilla campaign 
     factions, and the psfs (Permanent Stone Forts) set is empty. Any 
     of these sets  can be modified using the configuration files and 
     new sets can be added as well.

     The configuration file is written in YAML (YAML Aint Markup 
     Language). The specification for YAML can be found at 
     http://yaml.org. Only a very limited knowledge of YAML is needed 
     to modify the configuration files. Here is a brief summary of YAML 
     syntax:

        * YAML is a plain text format. YAML files can be edited with 
          any plain text editor.
        * In YAML, comments are indicated by the hash character (`#').
          All text from after the hash character to the end of the line 
          are considered part of the comment and are not interpreted.
        * In YAML, a key is linked to a value using the colon (`:') 
          operator. the DotS Replicator configuration file has five 
          keys that must be mapped to values: `comment,' 
          `command_prefix,' `factions,' `settlements,' and so on.
        * YAML supports many datatypes and many different syntaxes for 
          representing these datatypes, but the DotS replicator 
          configuration file uses only two YAML datatypes (strings and 
          sequences) and a single way of representing each of these.
        * A YAML string can be specified either by simply typing in the 
          value or by putting the value in quotes. (value, 'value', and 
          "value" are all valid representations of the string `value.')
        * A YAML sequence is specified by surrounding a list of values 
          with brackets (`[' and `]'). Values within the sequences must 
          be separated with commas (`,').

     That five minute tutorial contains enough information for you to 
     begin modifying the configuration file on your own. You can begin 
     either by editing the file `default.yaml' or creating your own 
     configuration file and passing it as an argument to 
     dots_replicator on the command line. (See USAGE for more 
     information on command line options.)

     Here is a list of the values that can be specified in the YAML 
     configuration file.

         NAME            TYPE                 DESCRIPTION

         command prefix  string               A string that must 
                                              precede all DotS 
                                              Replicator macro commands

         comment         string               The string that 
                                              represents a comment in 
                                              the language in which 
                                              DotS Replicator macros 
                                              are being embedded. 
                                              Unless this option is set 
                                              to a null string, all 
                                              macros must appear within 
                                              a comment.

         *any*           sequence of strings  A set of items.

VIII. The default.yaml configuration file that is distributed with DotS 
      Replicator comes with several built-in convenience sets targeted 
      at the vanilla M2TW Grand Campaign. Here is a list of the built-
      in sets:

         NAME            DESCRIPTION

         factions        All twenty-two internal faction names listed 
                         in alphabetical order. (With the exception of 
                         `slave,' which is at the end of the set.)

         Factions        All twenty-two faction names listed in 
                         alphabetical order and capitalized. (With the 
                         exception of `Slave,' which is at the end of 
                         the set.) These names are not the scripting 
                         identifiers of the factions. However, they are 
                         valid internal names. This set could be useful 
                         in creating internal trait and trigger names.

         nationalities   Nationalities for all twenty-two factions 
                         listed in alphabetical order. (With the 
                         exception of `rebel,' which is at the end of 
                         the set.) These names are not the scripting 
                         identifiers of the factions. However, they are 
                         valid internal names. This set could be useful 
                         in creating internal trait and trigger names.

         Nationalities   Nationalities for all twenty-two factions 
                         listed in alphabetical order and capitalized. 
                         (With the exception of `rebel,' which is at 
                         the end of the set.) These names are not the 
                         scripting identifiers of the factions. 
                         However, they are valid internal names. This 
                         set could be useful in creating internal trait 
                         and trigger names.

         Regions         Internal names for all 112 regions. 
                         (Capitalized as per the convention for 
                         internal region names.) The set is NOT 
                         organized in alphabetical order, but is paired 
                         with the `Settlements' set so that the two can 
                         be used together with the `with above' 
                         statement.

         Settlements     Internal names for all 112 settlements listed 
                         in alphabetical order. (Capitalized as per the 
                         convention for internal settlement names.)
