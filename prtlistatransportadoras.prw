#Include 'totvs.ch'
#Include 'parmtype.ch'
#Include "RestFul.CH"
//-------------------------------------------------------------------
/*/{Protheus.doc} PRTLISTATRANSPORTADORAS
Servi�o REST de lista de transportadoras dispon�vel para o portal de vendas

@author Felipe Toledo
@since 11/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSRESTFUL PRTLISTATRANSPORTADORAS DESCRIPTION "Servi�o REST de listas de transportadoras dispon�veis portal de vendas"

WSDATA CFILTROSQL As String OPTIONAL // String com filtro SQL
WSDATA NPAGE      As Integer OPTIONAL // Numero da pagina

WSMETHOD GET DESCRIPTION "Retorna todos os transportadoras disponiveis para o portal de vendas" WSSYNTAX "/PRTLISTATRANSPORTADORAS/{CODIGO_TRANSPORTADORA} "
 
END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET
Processa as informa��es e retorna o json
@author Felipe Toledo
@since 11/07/17
@type Method
/*/
//-------------------------------------------------------------------
WSMETHOD GET WSRECEIVE CFILTROSQL, NPAGE WSSERVICE PRTLISTATRANSPORTADORAS
Local oObjResp   := Nil
Local cJson      := ''
Local cAliasQry  := GetNextAlias()
Local oObjResp   := PrtListaTransportadoras():New() // --> Objeto que ser� serializado
Local cCodTransp := '' // Codigo da transportadora
Local cWhere     := ''
Local cWhere2    := ''
Local cFiltroSql := Self:CFILTROSQL
Local nPage      := Self:NPAGE
Local nRegPag    := 500 // Registros por pagina
Local cPagDe     := ''
Local cPagAte    := ''
Local lRet      := .T.

//-------------------------------------------------------------
// Filtro na sele��o dos registros
//-------------------------------------------------------------
If Len(::aUrlParms) > 0
	cCodTransp := ::aUrlParms[1] // Recebe o codigo da transportadora
EndIf

cWhere :="%"
If ! Empty(cCodTransp)
	// Filtra transportadora
	cWhere += " AND SA4.A4_COD   = '" + cCodTransp + "' "
EndIf

If ! Empty(cFiltroSql)
	// Filtro SQL 
	cWhere += " AND " + cFiltroSql
EndIf

cWhere +="%"

// Controle de pagina��o
cWhere2 := "%"
If !Empty(nPage) .And. nPage > 0
	cPagDe  := AllTrim(Str((nPage * nRegPag) - (nRegPag-1)))
	cPagAte := Alltrim(Str(nPage * nRegPag))
	
	cWhere2 += " WHERE LINHA BETWEEN " + cPagDe + " AND " + cPagAte + " "
EndIf
cWhere2 += "%"

// Query para listar os dados
BeginSql Alias cAliasQry
    SELECT A4_COD, A4_NOME, A4_CGC
      FROM (
	SELECT ROW_NUMBER() OVER (ORDER BY A4_COD, A4_COD) AS LINHA, A4_COD, A4_NOME, A4_CGC
	  FROM %Table:SA4% SA4
	 WHERE SA4.A4_FILIAL = %xFilial:SA4%
	   %Exp:cWhere%
	   AND SA4.%notDel%) TRB
	   %Exp:cWhere2%
	 ORDER
	    BY A4_COD
EndSql

If (cAliasQry)->( ! Eof() )
	//Cria um objeto da classe para fazer a serializa��o na fun��o FWJSONSerialize
	(cAliasQry)->(DbEval({||;
	oObjResp:Add( PrtItListaTransportadoras():New( A4_COD, A4_NOME, A4_CGC ) );
	}))
Else
	SetRestFault(400, "Lista de transportadoras vazia")
	lRet := .F.
EndIf

// --> Transforma o objeto de clientes em uma string json
cJson := FWJsonSerialize(oObjResp,.F.)

// define o tipo de retorno do m�todo
::SetContentType("application/json")

// --> Envia o JSON Gerado para a aplica��o Client
::SetResponse(cJson)

(cAliasQry)->(DbCloseArea())

Return(lRet)