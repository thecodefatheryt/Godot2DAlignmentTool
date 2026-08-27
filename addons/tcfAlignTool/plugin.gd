@tool
extends EditorPlugin

var baslikLabel: Label
var yatayButon: Button
var dikeyButon: Button
var editorInterface: EditorInterface
var eklentiAraclari: Array = []

func _enable_plugin() -> void:
	editorInterface = get_editor_interface()

	# 1. Başlık Yazısını Oluştur
	baslikLabel = Label.new()
	baslikLabel.text = "Align Items :"
	
	# 2. Yatay Hizalama Butonunu Oluştur (Y ekseninde eşitler)
	yatayButon = Button.new()
	yatayButon.text = " ↔ "
	yatayButon.tooltip_text = "Centers selected items on Y axis"
	yatayButon.pressed.connect(alignHorizontal)
	
	# 3. Dikey Hizalama Butonunu Oluştur (X ekseninde eşitler)
	dikeyButon = Button.new()
	dikeyButon.text = " ↕ "
	dikeyButon.tooltip_text = "Centers selected items on X axis"
	dikeyButon.pressed.connect(alignVertical)
	
	eklentiAraclari = [baslikLabel, yatayButon, dikeyButon]
	
	# Araçları üst menüye ekle
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, baslikLabel)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, yatayButon)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, dikeyButon)
	
	# Seçim sinyalini bağla
	editorInterface.get_selection().selection_changed.connect(onSelectionChanged)
	onSelectionChanged()

func _disable_plugin() -> void:
	if editorInterface and editorInterface.get_selection().selection_changed.is_connected(onSelectionChanged):
		editorInterface.get_selection().selection_changed.disconnect(onSelectionChanged)
		
	for arac in eklentiAraclari:
		if arac:
			arac.queue_free()
	eklentiAraclari.clear()

# --- SEÇİM DEĞİŞİM KONTROLÜ (TÜM 2D NESNELER İÇİN) ---
func onSelectionChanged() -> void:
	if not editorInterface: return
	
	var secim = editorInterface.get_selection().get_selected_nodes()
	
	# En az 2 nesne seçildiyse VE seçilenlerin TEPESİNDEKİLER CanvasItem (UI veya 2D) ise göster
	var uygunMu: bool = secim.size() >= 2
	if uygunMu:
		for nesne in secim:
			# Filtreyi Control yerine CanvasItem yaparak tüm 2D dünyasına kapıyı açtık!
			if not nesne is CanvasItem:
				uygunMu = false
				break
				
	for arac in eklentiAraclari:
		if arac: 
			arac.visible = uygunMu

# --- ASIL MERKEZ HİZALAMA MOTORU ---
func alignVertical() -> void:
	var secili_nesneler = editorInterface.get_selection().get_selected_nodes()
	if secili_nesneler.size() < 2: return
	
	var referans_merkez_y: float = 0.0
	# HATA ÇÖZÜMÜ: Buradaki 'is Control' kalıntısını jilet gibi temizleyip CanvasItem yaptık!
	if secili_nesneler[0] is CanvasItem:
		referans_merkez_y = _get_node_center(secili_nesneler[0]).y
		
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Yatay Hizala")
	
	for i in range(1, secili_nesneler.size()):
		var nesne = secili_nesneler[i]
		if nesne is CanvasItem:
			var mevcut_merkez = _get_node_center(nesne)
			var fark_y = referans_merkez_y - mevcut_merkez.y
			
			var eski_pos = nesne.position
			var yeni_pos = nesne.position + Vector2(0, fark_y)
			
			undo_redo.add_do_property(nesne, "position", yeni_pos)
			undo_redo.add_undo_property(nesne, "position", eski_pos)
			
	undo_redo.commit_action()

func alignHorizontal() -> void:
	var secili_nesneler = editorInterface.get_selection().get_selected_nodes()
	if secili_nesneler.size() < 2: return
	
	var referans_merkez_x: float = 0.0
	# HATA ÇÖZÜMÜ: Buradaki 'is Control' kalıntısını da jilet gibi temizleyip CanvasItem yaptık!
	if secili_nesneler[0] is CanvasItem:
		referans_merkez_x = _get_node_center(secili_nesneler[0]).x
		
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Dikey Hizala")
	
	for i in range(1, secili_nesneler.size()):
		var nesne = secili_nesneler[i]
		if nesne is CanvasItem:
			var mevcut_merkez = _get_node_center(nesne)
			var fark_x = referans_merkez_x - mevcut_merkez.x
			
			var eski_pos = nesne.position
			var yeni_pos = nesne.position + Vector2(fark_x, 0)
			
			undo_redo.add_do_property(nesne, "position", yeni_pos)
			undo_redo.add_undo_property(nesne, "position", eski_pos)
			
	undo_redo.commit_action()

# --- MERKEZ NOKTASI HESAPLAMA MOTORU ---
func _get_node_center(node: Node) -> Vector2:
	if node is Control:
		return node.position + (node.size / 2.0)
	elif node is Node2D:
		if node.has_method("get_rect"):
			# Sprite2D gibi nesnelerin kendi local offset'lerini de hesaba katarak tam merkezini bulur
			return node.position + node.get_rect().get_center()
		return node.position
	return Vector2.ZERO
