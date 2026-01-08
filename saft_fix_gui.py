import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
from pathlib import Path
import logging
from saft_core import corrigir_saft

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DOC_TYPES = ["FT", "FR", "FS", "NC", "ND"]

class SAFTFixGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("SAFT-Fix")
        self.root.geometry("600x700")
        
        # Variáveis
        self.entrada = tk.StringVar()
        self.saida = tk.StringVar()
        self.sales_var = tk.BooleanVar(value=True)
        self.working_var = tk.BooleanVar(value=False)
        
        self.doc_vars = {t: tk.BooleanVar(value=False) for t in DOC_TYPES}
        self.serie_vars = {t: tk.StringVar() for t in DOC_TYPES}
        self.atcud_vars = {t: tk.StringVar() for t in DOC_TYPES}
        
        self.serie_working = tk.StringVar()
        self.atcud_working = tk.StringVar()
        
        self.setup_ui()
    
    def setup_ui(self):
        # SAFT files
        tk.Label(self.root, text="SAFT original").grid(row=0, column=0, sticky="w", padx=5, pady=5)
        tk.Entry(self.root, textvariable=self.entrada, width=45).grid(row=0, column=1, padx=5, pady=5)
        tk.Button(self.root, text="Abrir", command=self.abrir_entrada).grid(row=0, column=2, padx=5, pady=5)
        
        tk.Label(self.root, text="SAFT corrigido").grid(row=1, column=0, sticky="w", padx=5, pady=5)
        tk.Entry(self.root, textvariable=self.saida, width=45).grid(row=1, column=1, padx=5, pady=5)
        tk.Button(self.root, text="Guardar", command=self.guardar_saida).grid(row=1, column=2, padx=5, pady=5)
        
        # SalesInvoices
        tk.Checkbutton(self.root, text="SalesInvoices", variable=self.sales_var).grid(
            row=2, column=0, sticky="w", padx=5, pady=5
        )
        
        row = 3
        tk.Label(self.root, text="Tipo", font=("Arial", 9, "bold")).grid(row=row, column=0, padx=5)
        tk.Label(self.root, text="Série", font=("Arial", 9, "bold")).grid(row=row, column=1, padx=5)
        tk.Label(self.root, text="ATCUD", font=("Arial", 9, "bold")).grid(row=row, column=2, padx=5)
        row += 1
        
        for t in DOC_TYPES:
            tk.Checkbutton(self.root, text=t, variable=self.doc_vars[t]).grid(row=row, column=0, padx=5)
            tk.Entry(self.root, textvariable=self.serie_vars[t], width=15).grid(row=row, column=1, padx=5)
            tk.Entry(self.root, textvariable=self.atcud_vars[t], width=20).grid(row=row, column=2, padx=5)
            row += 1
        
        # WorkingDocuments
        tk.Checkbutton(self.root, text="WorkingDocuments", variable=self.working_var).grid(
            row=row, column=0, sticky="w", padx=5, pady=5
        )
        row += 1
        
        tk.Label(self.root, text="Série Working").grid(row=row, column=0, sticky="w", padx=5)
        tk.Entry(self.root, textvariable=self.serie_working, width=20).grid(row=row, column=1, padx=5)
        row += 1
        
        tk.Label(self.root, text="ATCUD Working").grid(row=row, column=0, sticky="w", padx=5)
        tk.Entry(self.root, textvariable=self.atcud_working, width=20).grid(row=row, column=1, padx=5)
        row += 1
        
        tk.Button(self.root, text="Executar", command=self.executar, bg="#4CAF50", fg="white", 
                 font=("Arial", 10, "bold")).grid(row=row, column=1, pady=10)
        row += 1
        
        # Área de log
        tk.Label(self.root, text="Log de alterações:").grid(row=row, column=0, columnspan=3, sticky="w", padx=5, pady=5)
        row += 1
        
        self.log_text = scrolledtext.ScrolledText(self.root, height=10, width=70)
        self.log_text.grid(row=row, column=0, columnspan=3, padx=5, pady=5)
    
    def abrir_entrada(self):
        filename = filedialog.askopenfilename(filetypes=[("XML", "*.xml"), ("Todos", "*.*")])
        if filename:
            self.entrada.set(filename)
            # Sugerir nome de saída automaticamente
            if not self.saida.get():
                path = Path(filename)
                self.saida.set(str(path.parent / f"{path.stem}_corrigido.xml"))
    
    def guardar_saida(self):
        filename = filedialog.asksaveasfilename(
            defaultextension=".xml",
            filetypes=[("XML", "*.xml"), ("Todos", "*.*")]
        )
        if filename:
            self.saida.set(filename)
    
    def validar_entrada(self):
        """Valida os campos antes de executar."""
        if not self.entrada.get():
            raise ValueError("Seleciona o ficheiro SAFT original")
        
        if not Path(self.entrada.get()).exists():
            raise ValueError(f"Ficheiro não encontrado: {self.entrada.get()}")
        
        if not self.saida.get():
            raise ValueError("Seleciona o ficheiro de saída")
        
        sales_config = {}
        if self.sales_var.get():
            for t in DOC_TYPES:
                if self.doc_vars[t].get():
                    serie = self.serie_vars[t].get().strip()
                    atcud = self.atcud_vars[t].get().strip()
                    
                    if not serie or not atcud:
                        raise ValueError(f"Falta série ou ATCUD para {t}")
                    
                    sales_config[t] = {"serie": serie, "atcud": atcud}
            
            if not sales_config:
                raise ValueError("Seleciona pelo menos um tipo de SalesInvoices")
        
        working_config = None
        if self.working_var.get():
            if not self.serie_working.get() or not self.atcud_working.get():
                raise ValueError("Falta série ou ATCUD para WorkingDocuments")
            
            working_config = {
                "serie": self.serie_working.get().strip(),
                "atcud": self.atcud_working.get().strip()
            }
        
        if not sales_config and not working_config:
            raise ValueError("Seleciona pelo menos SalesInvoices ou WorkingDocuments")
        
        return sales_config, working_config
    
    def executar(self):
        self.log_text.delete(1.0, tk.END)
        self.log_text.insert(tk.END, "A processar...\n")
        self.root.update()
        
        try:
            sales_config, working_config = self.validar_entrada()
            
            changes = corrigir_saft(
                input_file=self.entrada.get(),
                output_file=self.saida.get(),
                sales_config=sales_config if sales_config else None,
                working_config=working_config
            )
            
            # Mostrar resultados
            self.log_text.delete(1.0, tk.END)
            self.log_text.insert(tk.END, f"Processamento concluído!\n\n")
            self.log_text.insert(tk.END, f"Total de documentos corrigidos: {len(changes)}\n\n")
            
            if changes:
                self.log_text.insert(tk.END, "Alterações realizadas:\n")
                self.log_text.insert(tk.END, "-" * 60 + "\n")
                for tipo, doc_type, original, novo in changes:
                    self.log_text.insert(tk.END, f"[{tipo}] {doc_type}: {original} -> {novo}\n")
            
            messagebox.showinfo(
                "Concluído",
                f"Documentos corrigidos: {len(changes)}\n\nVer detalhes na área de log."
            )
            
        except FileNotFoundError as e:
            messagebox.showerror("Erro", f"Ficheiro não encontrado:\n{e}")
            logger.error(str(e))
        except Exception as e:
            messagebox.showerror("Erro", f"Erro ao processar:\n{e}")
            logger.error(str(e), exc_info=True)
            self.log_text.insert(tk.END, f"\nErro: {e}\n")

if __name__ == "__main__":
    root = tk.Tk()
    app = SAFTFixGUI(root)
    root.mainloop()

