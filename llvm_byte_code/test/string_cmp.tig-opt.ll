; ModuleID = 'llvm_byte_code/test/string_cmp.tig.ll'
source_filename = "Tiger jit"

@0 = private unnamed_addr constant [12 x i8] c"test string\00"
@1 = private unnamed_addr constant [13 x i8] c"-hello world\00"
@2 = private unnamed_addr constant [24 x i8] c"test string-hello world\00"

declare i8* @tig_concat(i8*, i8*) local_unnamed_addr

declare void @assert_equal_string(i8*, i8*) local_unnamed_addr

define i32 @main() local_unnamed_addr {
entry:
  call void @assert_equal_string(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0))
  %0 = call i8* @tig_concat(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @0, i32 0, i32 0), i8* getelementptr inbounds ([13 x i8], [13 x i8]* @1, i32 0, i32 0))
  call void @assert_equal_string(i8* %0, i8* getelementptr inbounds ([24 x i8], [24 x i8]* @2, i32 0, i32 0))
  ret i32 0
}
