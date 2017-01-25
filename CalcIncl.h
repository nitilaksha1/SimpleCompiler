typedef enum {typeCon, typeId, typeOpr}nodeEnum;

//Definition for constant type nodes
typedef struct{
	nodeEnum type;
	int value;
}conNodeType;

//Definition for identifiers
typedef struct{
	nodeEnum type;
	int idval;           /*Subscript to id array*/
}idNodeType;

//Definition for operator type nodes
typedef struct {
	nodeEnum type;
	int oper;		//Operator
	int nops;	//Number of operands
	union nodeTypeTag *op[1]; //Variable number of operands
}oprNodeType;

typedef union nodeTypeTag {
	nodeEnum type;		//Node type
	conNodeType con;	/*constants*/
	idNodeType id;      /*identifiers*/
	oprNodeType opr;	/*operators*/
}nodeType;

extern int sym[26];			//symbol table
