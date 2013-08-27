:NameSpace UT

:Class UTresult
        :Field Public Crashed
        :Field Public Passed
        :Field Public Failed
        :Field Public Text
        :Field Public Returned
        :Field Public Name

        ∇ UTresult
        :Access Public
        :Implements Constructor
        Crashed ← 0
        Passed ← 0
        Failed ← 0
        Returned ← ⍬
        Text ← ''
        Name ← ''
        ∇
:EndClass 

:Class UTcover
        :Field Public Page_name
        :Field Public Pages
        :Field Public Cover
        
        ∇ coverobj
        :Access Public
        :Implements Constructor
        Pages ← ⍬
        Cover ← ⍬
        Page_name ← ⍬
        ∇
        
:EndClass

:Class CoverResult
        :Field Public CoveredLines
        :Field Public FunctionLines
        :Field Public Representation
        :Field Public NC
        ∇ coverresult
        :Access Public
        :Implements Constructor
        CoveredLines ← ⍬
        FunctionLines ← ⍬
        Representation ← ⍬
        NC ← 0
        ∇
:EndClass

expect ← ⍬
exception ← ⍬
nexpect ← ⍬

∇ {Z} ← {CoverConf} run Argument;PRE_test;POST_test;TEST_step;COVER_step_function;COVER_step;FromSpace

        load_display_if_not_already_loaded

        FromSpace ← 1 ⊃ ⎕RSI

        PRE_test ← {}
        POST_test ← {}
        COVER_step ← {} 
        :If 0 ≠ ⎕NC 'CoverConf'
                PRE_test ← { ⎕PROFILE 'start' }
                POST_test ← { ⎕PROFILE 'stop' }
        :EndIf

        :If is_function Argument
                TEST_step ← single_function_test_function
                COVER_file ← Argument,'_coverage.html'

        :ElseIf is_list_of_functions Argument
                TEST_step ← list_of_functions_test_function
                COVER_file ← 'list_coverage.html'

        :ElseIf is_file Argument
                TEST_step ← file_test_function
                COVER_file ← (get_file_name Argument),'_coverage.html'

        :ElseIf is_dir Argument
                test_files ← test_files_in_dir Argument
                TEST_step ← { #.UT.run ¨ ⍵ }
                Argument ← test_files
        :EndIf

        :If 0 ≠ ⎕NC 'CoverConf'
                COVER_step ← { CoverConf.Page_name ← COVER_file ⋄ generate_coverage_page CoverConf }
        :EndIf                

        PRE_test ⍬
        Z ← FromSpace TEST_step Argument
        POST_test ⍬
        COVER_step ⍬
∇

∇ load_display_if_not_already_loaded
        :If 0=⎕NC '#.DISPLAY'
                'DISPLAY' #.⎕CY 'display'
        :EndIf
∇

∇ Z ← FromSpace single_function_test_function TestName;test_data
        ut_data ← FromSpace TestName
        Z ← run_ut ut_data
∇

∇ Z ← FromSpace list_of_functions_test_function ListOfNames
        ut_datas ← { FromSpace ⍵ } ¨ ListOfNames
        Z ← run_ut ¨ ut_datas
        ('Test execution report') print_passed_crashed_failed Z
∇

∇ Z ← FromSpace file_test_function FilePath;FileNS;Functions;TestFunctions;ut_datas
        FileNS ← ⎕SE.SALT.Load FilePath,' -target=#'
        Functions  ← ↓ FileNS.⎕NL 3
        TestFunctions ←  (is_test ¨ Functions) / Functions
        ut_datas ← { FileNS ⍵ } ¨ TestFunctions
        Z ← run_ut ¨ ut_datas
        (FilePath,' tests') print_passed_crashed_failed Z
∇

∇ Z ← get_file_name Argument;separator
        separator ← ⌈ / ('/' = Argument) / ⍳ ⍴ Argument
        Z ← ¯7 ↓ separator ↓ Argument
∇

∇ generate_coverage_page CoverConf;ProfileData;CoverResults;HTML
        ProfileData ← ⎕PROFILE 'data'       
        ToCover ← retrieve_coverables ¨ CoverConf.Cover
        :if (⍴ToCover) ≡ (⍴⊂1)
                ToCover ← ⊃ ToCover
        :endif
        Representations ← get_representation ¨ ToCover
        CoverResults ← ProfileData∘generate_cover_result ¨ ↓ ToCover,[1.5]Representations
        HTML ← generate_html CoverResults
        CoverConf write_html_to_page HTML
        ⎕PROFILE 'clear'
∇

∇ Z ← retrieve_coverables Something;nc;functions
  nc ← ⎕NC Something
  :if nc = 3
          Z ← Something
  :elseif nc = 9
          functions ← strip ¨ ↓ ⍎ Something,'.⎕NL 3'
          Z ← { (Something,'.',⍵) } ¨ functions 
  :endif
∇

∇ Z ← strip input
  Z ← (input≠' ')/input
∇

∇ Z ← get_representation Function;nc;rep
  nc ← ⎕NC ⊂Function
  :if nc = 3.1
          rep ← ↓ ⎕CR Function
          rep[1] ← ⊂'∇',⊃rep[1]
          rep,← ⊂'∇'
          rep ← ↑ rep 
  :else
          rep ← ⎕CR Function
  :endif
  Z ← rep
∇

∇ Z ← ProfileData generate_cover_result Args;FunctionName;FunctionVR;Indices;Lines;Res
        (FunctionName Representation) ← Args
        Indices ← ({ FunctionName ≡ ⍵ } ¨ ProfileData[;1]) / ⍳ ⍴ ProfileData[;1]
        Lines ← ProfileData[Indices;2]
        Res ← ⎕NEW CoverResult
        Res.NC ← ⎕NC ⊂FunctionName
        :if 3.1 = Res.NC
                Res.FunctionLines ← ¯2 + ⍴ ↓ Representation
        :else
                Res.FunctionLines ← ⊃ ⍴ ↓ Representation
        :endif
        Res.CoveredLines ← (⍬∘≢ ¨ Lines) / Lines
        Res.Representation ← Representation
        Z ← Res
∇

∇ Z ← generate_html CoverResults;TotalCov;Covered;Total;Percentage;CoverageText;ColorizedCode;Timestamp;Page
        TotalCov ← ⎕NEW CoverResult
        Covered ← ⊃⊃+/ { ⍴ ⍵.CoveredLines } ¨ CoverResults
        Total ← ⊃⊃+/ { ⍵.FunctionLines } ¨ CoverResults
        Percentage ← 100 × Covered ÷ Total
        CoverageText ← 'Coverage: ',Percentage,'% (',Covered,'/',Total,')'
        ColorizedCode ← ⊃ ,/ { colorize_code_by_coverage ⍵ } ¨ CoverResults
        Timestamp ← generate_timestamp_text
        Page ← ⍬
        Page ,← ⊂ ⍬,'<html>'
        Page ,← ⊂ ⍬,'<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>'
        Page ,← ⊂ ⍬,CoverageText
        Page ,← ColorizedCode
        Page ,← Timestamp
        Page ,← ⊂ ⍬,'</html>'
        Z ← Page
∇

∇ Z ← colorize_code_by_coverage CoverResult;Color;red_font;green_font;black_font;end_of_line
        Color ← { '<font color=',⍵,'><pre>' } 
        red_font ← Color 'red'
        green_font ← Color 'green'
        black_font ← Color 'black'
        end_of_line ← '</pre></font>'

        :if 3.1=CoverResult.NC
                Colors ← (2  + CoverResult.FunctionLines) ⍴ ⊂ ⍬,red_font
                Colors[1] ← ⊂ black_font
                Colors[⍴Colors] ← ⊂ black_font
        :else
                Colors ← CoverResult.FunctionLines ⍴ ⊂ ⍬,red_font
        :endif
        Colors[1+CoverResult.CoveredLines] ← ⊂ ⍬,green_font

        Code ← ↓ CoverResult.Representation
        Z ← Colors,[1.5]Code
        Z ← {⍺,(⎕UCS 13),⍵ }/ Z, (⍴ Code) ⍴ ⊂ ⍬,end_of_line
∇

∇ Z ← generate_timestamp_text;TS;YYMMDD;HHMMSS
        TS ← ⎕TS
        YYMMDD ← ⊃ { ⍺,'-',⍵} / 3 ↑ TS
        HHMMSS ← ⊃ { ⍺,':',⍵} / 3 ↑ 3 ↓ TS
        Z ← 'Page generated: ',YYMMDD,'|',HHMMSS
∇

∇ CoverConf write_html_to_page Page;tie;filename
        filename ← CoverConf.Pages,CoverConf.Page_name
        :Trap 22
                tie ← filename ⎕NTIE 0
                filename ⎕NERASE tie
                filename ⎕NCREATE tie
        :Else
                tie ← filename ⎕NCREATE 0
        :EndTrap
        Simple_array ← ⍕ ⊃ ,/ Page
        (⎕UCS 'UTF-8' ⎕UCS Simple_array) ⎕NAPPEND tie
∇

∇ Z ← is_function Argument
        Z ← '_TEST' ≡ ¯5 ↑ Argument
∇

∇ Z ← is_list_of_functions Argument
        Z ← 2 =≡ Argument
∇

∇ Z ← is_file Argument
        Z ← '.dyalog' ≡ ¯7 ↑ Argument
∇

∇ Z ← is_dir Argument
        Z ← 'yes' ≡ ⊃ ⎕CMD 'test -d ',Argument,' && echo yes || echo no'
∇

∇ Z ← test_files_in_dir Argument
        Z ← ⎕CMD 'ls ',Argument,'*_tests.dyalog'
∇

∇ Z ← run_ut ut_data;UTRes
        UTRes ← execute_function ut_data
        determine_pass_or_fail UTRes
        determine_message UTRes
        print_message_to_screen UTRes
        Z ← UTRes
∇

∇ Z ← execute_function ut_data;UTRes
        UTRes ← ⎕NEW UTresult
        UTRes.Name ← ⊃ut_data[2]
        reset_UT_globals
        :Trap 0
                UTRes.Returned ← ⍎ (⍕⊃ut_data[1]),'.',⊃ut_data[2]
        :Else
                UTRes.Returned ← 1 ⊃ ⎕DM
                :If exception ≢ ⍬
                        expect ← exception
                :Else
                        UTRes.Crashed ← 1
                :EndIf
        :EndTrap        
        Z ← UTRes                
∇

∇ reset_UT_globals
        expect ← ⍬
        exception ← ⍬
        nexpect ← ⍬  
∇

∇ Z ← is_test FunctionName;wsIndex
        wsIndex ← FunctionName ⍳ ' '
        FunctionName ← (wsIndex - 1) ↑ FunctionName
        Z ← '_TEST' ≡ ¯5 ↑ FunctionName
∇

∇ Heading print_passed_crashed_failed ArrayRes
        ⎕ ← '-----------------------------------------'
        ⎕ ← Heading
        ⎕ ← '    ⍋  Passed: ',+/ { ⍵.Passed } ¨ ArrayRes
        ⎕ ← '    ⍟ Crashed: ',+/ { ⍵.Crashed } ¨ ArrayRes
        ⎕ ← '    ⍒  Failed: ',+/ { ⍵.Failed } ¨ ArrayRes
∇

∇ determine_pass_or_fail UTRes
        :If 0 = UTRes.Crashed
                argument ← ⊃ (⍬∘≢ ¨ #.UT.expect #.UT.nexpect) / #.UT.expect #.UT.nexpect
                comparator ← (⍬∘≢ ¨ #.UT.expect #.UT.nexpect) / '≡' '≢'                 
                :if argument (⍎comparator) UTRes.Returned
                        UTRes.Passed ← 1
                :else
                        UTRes.Failed ← 1
                :endif
        :EndIf
∇

∇ determine_message UTRes
        :If UTRes.Crashed
                UTRes.Text ← 'CRASHED: ' failure_message UTRes
        :ElseIf UTRes.Passed
                UTRes.Text ← 'Passed'
        :Else
                UTRes.Text ← 'FAILED: ' failure_message UTRes
        :EndIf
∇

∇ print_message_to_screen UTRes
        ⎕ ← UTRes.Text
∇

∇ Z ← term_to_text Term;Text;Rows
        Text ← #.DISPLAY Term
        Rows ← 1 ⊃ ⍴ Text
        Z ← (Rows 4 ⍴ ''),Text
∇

∇ Z ← Cause failure_message UTRes;hdr;exp;expterm;got;gotterm
        hdr ← Cause,UTRes.Name
        exp ← 'Expected'
        expterm ← term_to_text #.UT.expect
        got ← 'Got'
        gotterm ← term_to_text UTRes.Returned
        Z ← align_and_join_message_parts hdr exp expterm got gotterm
∇

∇ Z ← align_and_join_message_parts Parts;hdr;exp;expterm;got;gotterm;R1;C1;R2;C2;W
        (hdr exp expterm got gotterm) ← Parts
        (R1 C1) ← ⍴ expterm
        (R2 C2) ← ⍴ gotterm
        W ← ⊃ ⊃ ⌈ / C1 C2 (⍴ hdr) (⍴ exp) (⍴ got) 
        Z ← (W ↑ hdr),[0.5] (W ↑ exp)
        Z ← Z⍪(R1 W ↑ expterm)
        Z ← Z⍪(W ↑ got)
        Z ← Z⍪(R2 W ↑ gotterm)
∇

:EndNameSpace