
#ifndef   ELASTO_CUDA

#define   ELASTO_CUDA

#ifndef      ELASTO__EXPORTS

#define     ELASTO_API __declspec(dllexport) //�������ź궨��


#else

#define     ELASTO_API __declspec(dllimport) //�������ź궨��

#endif

#include  <string>


 // #include  "lib_add_cuda.cuh"

// #include  "CElasto.h"  

//#include  "SysConfig.h"


struct  EInput    ;

struct  EOutput   ;

struct ConfigParam;

class   CudaMain ;


const  char DefaultElastoConfFile[] = ".\\config.ini";


ELASTO_API    class   ElastoCuda    {

	
private :

	std::string  *  initFile;

	CudaMain  *    cudaMain;

	ConfigParam *  config;



private:                         //��ȡԭʼRF���� ����ȡ�˲������ݣ���ȡ��������


	void   readRFData(const EInput & in);








public:

	ElastoCuda();



	~ElastoCuda(); 

	virtual bool  isAvailable();

	virtual int   ci() const { return 40 };

	virtual void  init(const std::string &ini_file);

	virtual bool  process( const EInput &input, EOutput &output);










};












#endif