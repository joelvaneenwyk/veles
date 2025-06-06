# CMake script to embed a file as a C array
# Usage: cmake -DINPUT_FILE=file.txt -DOUTPUT_FILE=file.c -DSYMBOL_NAME=symbol_name -P embed_file.cmake

file(READ "${INPUT_FILE}" FILE_CONTENT HEX)

# Convert hex string to C array format
string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," ARRAY_VALUES "${FILE_CONTENT}")
string(REGEX REPLACE ",$" "" ARRAY_VALUES "${ARRAY_VALUES}")

# Generate C file
file(WRITE "${OUTPUT_FILE}"
"/* Auto-generated file from ${INPUT_FILE} */
const char ${SYMBOL_NAME}[] = {
${ARRAY_VALUES}, 0x00
};
")

message(STATUS "Generated ${OUTPUT_FILE} with symbol ${SYMBOL_NAME}")
