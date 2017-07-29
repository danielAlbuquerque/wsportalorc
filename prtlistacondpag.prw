#Include 'totvs.ch'
#Include 'parmtype.ch'
#Include "RestFul.CH"
//-------------------------------------------------------------------
/*/{Protheus.doc} PRTLISTACONDPAG
Servi�o REST de lista de condi��o de pagamento para o portal de vendas

@author Felipe Toledo
@since 07/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSRESTFUL PRTLISTACONDPAG DESCRIPTION "Servi�o REST de lista de condi��o de pagamentos para portal de vendas"
WSDATA CICMSST As String OPTIONAL //String filtro ICMS-ST
WSDATA CFILTROSQL As String OPTIONAL//String com filtro SQL

WSMETHOD GET DESCRIPTION "Retorna as condi��es de pagamentos disponiveis para o portal de vendas" WSSYNTAX "/PRTLISTACONDPAG "
 
END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET
Processa as informa��es e retorna o json
@author Felipe Toledo
@since 07/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSMETHOD GET WSRECEIVE CICMSST, CFILTROSQL WSSERVICE PRTLISTACONDPAG
Local oObjResp  := Nil
Local cJson     := ''
Local cAliasQry := GetNextAlias()
Local oObjResp  := PrtListaCondPag():New() // --> Objeto que ser� serializado
Local cIcmsST   := Self:CICMSST
Local cFiltroSql:= Self:CFILTROSQL
Local cCodCond  := ''
Local cWhere    := ''
Local lRet      := .T.

// Converte string base64 para formato original
If !Empty(cFiltroSql)
	cFiltroSql := Decode64(cFiltroSql)
EndIf

//-------------------------------------------------------------
// Filtro na sele��o dos registros
//-------------------------------------------------------------
If Empty(cCodCond) .And. Len(::aUrlParms) > 0
	cCodCond := ::aUrlParms[1] // Recebe a condi��o de pagamento
EndIf

cWhere :="%"
If ! Empty(cCodCond)
	// Filtra determinada condi��o de pagamento
	cWhere += " AND SE4.E4_CODIGO = '" + cCodCond + "' "
EndIf

If Upper(AllTrim(cIcmsST)) == 'S'
	// Filtra somente condi��o de pagamento que gera ST separada
	cWhere += " AND SE4.E4_SOLID = 'S' "
EndIf

If ! Empty(cFiltroSql)
	// Filtro SQL 
	cWhere += " AND " + cFiltroSql
EndIf

cWhere +="%"

// Query para listar os dados
BeginSql Alias cAliasQry
	SELECT E4_CODIGO, E4_DESCRI, E4_SOLID
	  FROM %Table:SE4% SE4
	 WHERE SE4.E4_FILIAL = %xFilial:SE4%
	   %Exp:cWhere%
	   AND SE4.%notDel%
	 ORDER
	    BY E4_CODIGO
EndSql

If (cAliasQry)->( ! Eof() )
	//Cria um objeto da classe para fazer a serializa��o na fun��o FWJSONSerialize
	(cAliasQry)->(DbEval({||;
	oObjResp:Add( PrtItListaCondPag():New( E4_CODIGO, E4_DESCRI, E4_SOLID ) );
	}))
EndIf

// --> Transforma o objeto de produtos em uma string json
cJson := FWJsonSerialize(oObjResp,.F.)

// define o tipo de retorno do m�todo
::SetContentType("application/json")

// --> Envia o JSON Gerado para a aplica��o Client
::SetResponse(cJson)

(cAliasQry)->(DbCloseArea())

Return(lRet)