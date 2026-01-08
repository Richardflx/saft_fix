from lxml import etree
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import logging

logger = logging.getLogger(__name__)

def corrigir_saft(
    input_file: str,
    output_file: str,
    sales_config: Optional[Dict[str, Dict[str, str]]] = None,
    working_config: Optional[Dict[str, str]] = None,
    start: int = 1
) -> List[Tuple[str, str, str, str]]:
    """
    Corrige números de documentos duplicados num ficheiro SAFT XML.
    
    Args:
        input_file: Caminho para o ficheiro SAFT original
        output_file: Caminho para o ficheiro SAFT corrigido
        sales_config: Configuração para SalesInvoices (tipo -> {serie, atcud})
        working_config: Configuração para WorkingDocuments {serie, atcud}
        start: Número inicial para contadores
        
    Returns:
        Lista de tuplas (tipo, doc_type, original, novo) com as alterações
        
    Raises:
        FileNotFoundError: Se o ficheiro de entrada não existir
        etree.XMLSyntaxError: Se o XML for inválido
        ValueError: Se a configuração for inválida
    """
    # Validação de entrada
    input_path = Path(input_file)
    if not input_path.exists():
        raise FileNotFoundError(f"Ficheiro não encontrado: {input_file}")
    
    output_path = Path(output_file)
    if not output_path.parent.exists():
        raise ValueError(f"Directório de saída não existe: {output_path.parent}")
    
    # Ler e validar XML
    try:
        with open(input_file, "rb") as f:
            content = f.read()
        root = etree.fromstring(content)
    except etree.XMLSyntaxError as e:
        logger.error(f"Erro ao parsear XML: {e}")
        raise
    except Exception as e:
        logger.error(f"Erro ao ler ficheiro: {e}")
        raise
    
    # Tratamento robusto de namespaces
    ns = {}
    if root.nsmap:
        for prefix, uri in root.nsmap.items():
            # Usa 'ns' como prefixo padrão se não houver prefixo
            key = prefix if prefix else "ns"
            ns[key] = uri
    else:
        # Se não houver namespaces, usa None
        ns = {"ns": None}
    
    changes = []
    
    # =========================
    # SALES INVOICES
    # =========================
    if sales_config:
        try:
            # Tenta com namespace primeiro
            nodes = root.xpath(".//ns:SalesInvoices/ns:Invoice", namespaces=ns)
            if not nodes:
                # Tenta sem namespace se não encontrar
                nodes = root.xpath(".//SalesInvoices/Invoice")
        except Exception as e:
            logger.warning(f"Erro ao procurar SalesInvoices: {e}")
            nodes = []
        
        seen = {k: set() for k in sales_config}
        counters = {k: start for k in sales_config}
        
        for inv in nodes:
            # Tenta encontrar InvoiceNo com e sem namespace
            no_el = None
            if "ns" in ns:
                no_el = inv.find("ns:InvoiceNo", namespaces=ns)
            if no_el is None:
                no_el = inv.find("InvoiceNo")
            
            if no_el is None or not no_el.text:
                continue
            
            original = no_el.text.strip()
            if not original:
                continue
            
            parts = original.split()
            if not parts:
                continue
                
            doc_type = parts[0]
            
            if doc_type not in sales_config:
                continue
            
            if original in seen[doc_type]:
                cfg = sales_config[doc_type]
                
                new_no = f"{doc_type} {cfg['serie']}/{counters[doc_type]}"
                no_el.text = new_no
                
                # Atualizar ATCUD
                atcud_el = None
                if "ns" in ns:
                    atcud_el = inv.find("ns:ATCUD", namespaces=ns)
                if atcud_el is None:
                    atcud_el = inv.find("ATCUD")
                    
                if atcud_el is not None:
                    atcud_el.text = f"{cfg['atcud']}-{counters[doc_type]}"
                
                counters[doc_type] += 1
                changes.append(("Sales", doc_type, original, new_no))
                logger.info(f"Corrigido: {original} -> {new_no}")
            else:
                seen[doc_type].add(original)
    
    # =========================
    # WORKING DOCUMENTS
    # =========================
    if working_config:
        try:
            nodes = root.xpath(".//ns:WorkingDocuments/ns:WorkDocument", namespaces=ns)
            if not nodes:
                nodes = root.xpath(".//WorkingDocuments/WorkDocument")
        except Exception as e:
            logger.warning(f"Erro ao procurar WorkingDocuments: {e}")
            nodes = []
        
        seen = set()
        counter = start
        
        for doc in nodes:
            el = None
            if "ns" in ns:
                el = doc.find("ns:DocumentNumber", namespaces=ns)
            if el is None:
                el = doc.find("DocumentNumber")
                
            if el is None or not el.text:
                continue
            
            original = el.text.strip()
            if not original:
                continue
            
            if original in seen:
                parts = original.split()
                doc_type = parts[0] if parts else "WD"
                new_no = f"{doc_type} {working_config['serie']}/{counter}"
                el.text = new_no
                
                atcud_el = None
                if "ns" in ns:
                    atcud_el = doc.find("ns:ATCUD", namespaces=ns)
                if atcud_el is None:
                    atcud_el = doc.find("ATCUD")
                    
                if atcud_el is not None:
                    atcud_el.text = f"{working_config['atcud']}-{counter}"
                
                counter += 1
                changes.append(("Working", doc_type, original, new_no))
                logger.info(f"Corrigido: {original} -> {new_no}")
            else:
                seen.add(original)
    
    # Escrever ficheiro de saída
    try:
        with open(output_file, "wb") as f:
            f.write(
                etree.tostring(
                    root,
                    pretty_print=True,
                    xml_declaration=True,
                    encoding="UTF-8"
                )
            )
        logger.info(f"Ficheiro guardado: {output_file}")
    except Exception as e:
        logger.error(f"Erro ao escrever ficheiro: {e}")
        raise
    
    return changes

