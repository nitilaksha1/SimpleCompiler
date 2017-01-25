# SimpleCompiler

A simple compiler for a simple language consisting of while, assignments, if else, +, -, *, / operators and support
for single character variables.

Files:
-> Lex file (.l file) to extract tokens
-> Yacc file (.y file) to define syntax of simple language using grammar and translating the high level code to assembly code.
-> Sample c program to run.

TODO:
-> Implement type checking
-> Give better error messages

Running Instructions:
->Make sure all files are in same directory
->Run lex calclex.l on terminal
->Run yacc -d calcyacc.l on
->Run gcc lex.yy.c y.tab.c 
->Run ./a.out sampleprog.c
