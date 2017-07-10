#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include "RestFul.CH"

User Function PrtLogin()
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PRTLOGIN
Metodo para validar e retornar os dados do usu�rio informado.

Utilizar a autentica��o HTTP Basic no consumo de classes REST.
Envie no HEADER da requisi��o HTTP o campo Authorization conforme 
o modelo abaixo:

GET /PRTLOGIN
Host: localhost:8080
Accept: application/json
Authorization: BASIC YWRtaW46MTIzNDU2

usu�rio:senha no formato base64

@author Felipe Toledo
@since 07/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSRESTFUL PRTLOGIN DESCRIPTION "Servi�o REST para autenticar e retornar os dados do usu�rio do portal de vendas"

WSMETHOD GET DESCRIPTION "Retorna os dados do usu�rio do portal de venda" WSSYNTAX "/PRTLOGIN "
 
END WSRESTFUL
//-------------------------------------------------------------------
/*/{Protheus.doc} GET
Processa as informa��es e retorna o json
@author Felipe Toledo
@since 07/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSMETHOD GET WSSERVICE PRTLOGIN
Local oObjResp  := Nil
Local cJson     := ''
Local cCodUsr   := RetCodUsr() // Codigo do Usu�rio
Local cCodVen   := U_PrtCodVen() // Codigo do Vendedor
Local dDtAcesso := U_PrtDtUAc() // Data do �ltimo Acesso
Local cHrAcesso := U_PrtHrAc(dDtAcesso) // Hora do �ltimo acesso

//Cria um objeto da classe produtos para fazer a serializa��o na fun��o FWJSONSerialize
oObjResp := PrtLogin():New(cUserName,; // 1. Nome do usu�rio
                              cCodUsr,; // 2. Codigo do usu�rio
                              UsrFullName(cCodUsr),; // 3. Nome completo
                              UsrRetMail(cCodUsr),; // 4. e-mail
                              cCodVen,;  // 5. Codigo representante
                              dDtAcesso,; // 6. Data do ultimo acesso
                              cHrAcesso) // 7. Hora do ultimo acesso

//-- Grava Log indicando acesso usu�rio
ProcLogAtu('MENSAGEM','Acesso portal',Nil,'PRTLOGIN')

// --> Transforma o objeto de produtos em uma string json
cJson := FWJsonSerialize(oObjResp,.F.)

// define o tipo de retorno do m�todo
::SetContentType("application/json")

// --> Envia o JSON Gerado para a aplica��o Client
::SetResponse(cJson)

Return(.T.)