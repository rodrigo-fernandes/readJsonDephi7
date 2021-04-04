procedure TfrmPrincipal.btnExecutarClick(Sender: TObject);
var
  lJsonStream : TMemoryStream;
  jo, ja  : ISuperObject;
  i       : integer;
  Arquivo : string;
  lCpfCnpj_Socio : String;
  lEndereco : String;
  lBairro_Socio : String;
  lUF : String;
  lCidade : String;
  lReadJson : String;   
  lQryAux : TSDQuery;
  lQryInsert : TSDQuery;
  lNumero : String;
  lComplemento : String;
begin
  if (k_empresa <> C_CLIENTE_ITAJAI) then
  begin
    MessageDlg('Aplicativo não disponível para esta prefeitura!', mtInformation, [mbOk], 0);
    Abort;
  end;

  if (edtCaminhoArquivo.Text = EmptyStr) then
  begin
    MessageDlg('Carregue o arquivo primeiro!', mtInformation, [mbOk], 0);
    Abort;
  end;

  kbmPrincipal.EmptyTable;
  kbmPrincipal.DisableControls;
  lQryAux          := CriaQuery();
  lQryInsert       := CriaQuery();

  aguardeForm := Tfrm_Aguarde.Create(self);
  try
    try
      lQryAux.Close;
      lQryAux.SQL.Clear;
      lQryAux.SQL.Add('SELECT 1 AS VALOR ');
      lQryAux.SQL.Add('FROM pg_indexes ');
      lQryAux.SQL.Add('WHERE schemaname = ''public'' ');
      lQryAux.SQL.Add('  AND tablename = ''socio_ws'' ');
      lQryAux.Open;

      // Verifica se existe tabela para ser criada
	  if (lQryAux.IsEmpty) then
      begin
        lQryAux.Close;
        lQryAux.SQL.Clear;
        lQryAux.SQL.Add('create sequence socio_ws_id_seq; ');
        lQryAux.ExecSQL;

        lQryAux.Close;
        lQryAux.SQL.Clear;
        lQryAux.SQL.Add('create table socio_ws  ( ');
        lQryAux.SQL.Add('  sws_id integer primary key default nextval(''socio_ws_id_seq''), ');
        lQryAux.SQL.Add('  sws_cpfcnpj varchar(50), ');
        lQryAux.SQL.Add('  sws_endereco varchar(255), ');
        lQryAux.SQL.Add('  sws_bairro varchar(255), ');
        lQryAux.SQL.Add('  sws_uf varchar(50), ');
        lQryAux.SQL.Add('  sws_cidade varchar(255), ');
        lQryAux.SQL.Add('  sws_numero varchar(50), ');
        lQryAux.SQL.Add('  sws_complemento varchar(100) ');
        lQryAux.SQL.Add(' ); ');
        lQryAux.ExecSQL;
      end; 

      kbmPrincipal.Open;
      kbmPrincipal.EmptyTable;
      lJsonStream := TMemoryStream.Create;

      lJsonStream.LoadFromFile(edtCaminhoArquivo.Text);
      lJsonStream.Position := 0;

      SetLength(arquivo, lJsonStream.size);
      SetString(arquivo, PChar(lJsonStream.Memory), lJsonStream.Size div SizeOf(Char));

      lReadJson := Utf8ToAnsi(arquivo);
      jo := SuperObject.SO(lReadJson);

      ja := jo['registros'];

      aguardeForm.setaMaximo(2, 'Carergando constribuintes do arquivo JSON...etapa 1/2');
      for i := 0 to ja.asArray.length - 1 do
      begin
        lCpfCnpj_Socio := ja.AsArray[i].S['cpf_socio.cpfCnpj'];
        lEndereco      := ja.AsArray[i].S['endereco_correspondencia'];
        lBairro_Socio  := ja.AsArray[i].S['bairro_socio'];
        lUF            := ja.AsArray[i].S['uf_socio'];
        lCidade        := ja.AsArray[i].S['cidade_socio'];
        lNumero        := ja.AsArray[i].S['numero'];
        lComplemento   := ja.AsArray[i].S['complemento'];

        kbmPrincipal.Append;
        kbmPrincipal.FieldByName('cpfCnpj').AsString                  := lCpfCnpj_Socio;
        kbmPrincipal.FieldByName('endereco_correspondencia').AsString := lEndereco;
        kbmPrincipal.FieldByName('bairro_socio').AsString             := lBairro_Socio;
        kbmPrincipal.FieldByName('uf_socio').AsString                 := lUF;
        kbmPrincipal.FieldByName('cidade_socio').AsString             := lCidade;
        kbmPrincipal.FieldByName('numero').AsString                   := lNumero;
        kbmPrincipal.FieldByName('complemento').AsString              := lComplemento;
        kbmPrincipal.Post;

        lQryInsert.Close;
        lQryInsert.SQL.Clear;
        lQryInsert.SQL.Add('insert into socio_ws values (default, :cpfCnpj, :endereco_correspondencia, :bairro_socio, :uf_socio, :cidade_socio, :numero, :complemento ); ');
        lQryInsert.ParamByName('cpfCnpj').AsString                  := lCpfCnpj_Socio;
        lQryInsert.ParamByName('endereco_correspondencia').AsString := lEndereco;
        lQryInsert.ParamByName('bairro_socio').AsString             := lBairro_Socio;
        lQryInsert.ParamByName('uf_socio').AsString                 := lUF;
        lQryInsert.ParamByName('cidade_socio').AsString             := lCidade;
        lQryInsert.ParamByName('numero').AsString                   := IfThen(lNumero <> '', lNumero, '');
        lQryInsert.ParamByName('complemento').AsString              := IfThen(lComplemento <> '', lComplemento, '');
        lQryInsert.ExecSQL;

        aguardeForm.incrementa;
      end;
      aguardeForm.Hide;

      // Exclui tabela, sequence e registros criados
      lQryAux.Close;
      lQryAux.SQL.Clear;
      lQryAux.SQL.Add('DELETE FROM SOCIO_WS; ');
      lQryAux.ExecSQL;

      lQryAux.SQL.Clear;
      lQryAux.SQL.Add('DROP TABLE SOCIO_WS; ');
      lQryAux.ExecSQL;

      lQryAux.SQL.Clear;
      lQryAux.SQL.Add('DROP SEQUENCE SOCIO_WS_ID_SEQ; ');
      lQryAux.ExecSQL;

      aguardeForm.Hide;
      MessageDlg('Atualização concluída!' , mtInformation, [mbOk], 0);
    except
      on  E : Exception  do
      begin
        lJsonStream.Free;
        lQryAux.Close;
        lQryAux.Free;
        lQryInsert.Close;
        lQryInsert.Free;

        FinalizaTransacao(False);
        aguardeForm.Hide;
        //_AddLog('Erro na atualização = ' + e.Message);
        MessageDlg('Ocorreu um erro inesperado!' + #13 + E.Message, mtError, [mbOk], 0);
      end;
    end;
  finally
    FreeAndNil(lJsonStream);
    kbmPrincipal.EnableControls;
    FreeAndNil(lQryAux);
    FreeAndNil(lQryInsert);
    FreeAndNil(aguardeForm);
  end;
end;