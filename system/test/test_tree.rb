require_relative 'prerequisites'

class TreeTest < Test::Unit::TestCase

  def setup
    @accounts = Tree::TreeNode.new("Cuentas", "Plan de cuentas")

    activos = Tree::TreeNode.new("Activos", "Todo lo que tengo")
    disponibilidades = Tree::TreeNode.new("Disponibilidades")
    disponibilidades << Tree::TreeNode.new("Caja")
    disponibilidades << Tree::TreeNode.new("Banco")
    activos << disponibilidades

    bienes_de_cambio = Tree::TreeNode.new("Bienes de cambio")
    materiales = Tree::TreeNode.new("Materiales")
    materiales << Tree::TreeNode.new("TODOS LOS MATERIALES")
    materiales << Tree::TreeNode.new("Liquido corporal blanco")
    materiales << Tree::TreeNode.new("Liquido corporal rojo")
    bienes_de_cambio << materiales
    bienes_de_cambio << Tree::TreeNode.new("Productos") << Tree::TreeNode.new("TODOS LOS PRODUCTOS")
    activos << bienes_de_cambio

    reservas = Tree::TreeNode.new("Reservas")
    reservas << Tree::TreeNode.new("Reserva aguinaldos")
    reservas << Tree::TreeNode.new("Reserva vacaciones")
    activos << reservas

    bienes_de_uso = Tree::TreeNode.new("Bienes de uso")
    activos << bienes_de_uso

    @accounts << activos


    pasivos = Tree::TreeNode.new("Pasivos", "Todo lo que debo")
    deudas_comerciales = Tree::TreeNode.new("Deudas comerciales")
    deudas_comerciales  << Tree::TreeNode.new("Fondo de comercio a pagar")
    deudas_comerciales  << Tree::TreeNode.new("Servicios a pagar")
    deudas_comerciales  << Tree::TreeNode.new("Señas recibidas")
    deudas_comerciales  << Tree::TreeNode.new("Tarjeta de credito a pagar")
    pasivos << deudas_comerciales

    deudas_sociales = Tree::TreeNode.new("Deudas Sociales")
    deudas_sociales << Tree::TreeNode.new("Jornales a pagar")
    deudas_sociales << Tree::TreeNode.new("Comisiones a pagar")
    deudas_sociales << Tree::TreeNode.new("Sueldos a pagar")
    deudas_sociales << Tree::TreeNode.new("Aguinaldos a pagar")
    deudas_sociales << Tree::TreeNode.new("Vacaciones a pagar")
    deudas_sociales << Tree::TreeNode.new("Cargas sociales a pagar")
    pasivos << deudas_sociales

    deudas_fiscales = Tree::TreeNode.new("Deudas fiscales")
    deudas_fiscales << Tree::TreeNode.new("Impuestos a pagar")
    deudas_fiscales << Tree::TreeNode.new("IIBB a pagar")
    pasivos << deudas_fiscales

    otras_deudas = Tree::TreeNode.new("Otras deudas")
    pasivos << otras_deudas

    @accounts << pasivos


    resultados = Tree::TreeNode.new("Resultados")
    ventas = Tree::TreeNode.new("Ventas")
    ventas << Tree::TreeNode.new("Venta por mostrador")
    ventas << Tree::TreeNode.new("Venta por internet")
    resultados << ventas
    resultados << Tree::TreeNode.new("Costo mercaderia vendida")

    gastos_variables = Tree::TreeNode.new("Gastos variables")
    gastos_variables << Tree::TreeNode.new("Comisiones")
    gastos_variables << Tree::TreeNode.new("Jornales")
    gastos_variables << Tree::TreeNode.new("IIBB")
    gastos_variables << Tree::TreeNode.new("Fletes")
    proveedores = Tree::TreeNode.new("Proveedores") 
    proveedores << Tree::TreeNode.new("TODOS LOS PROVEEDORES")
    proveedores << Tree::TreeNode.new("Laca")
    gastos_variables << proveedores
    resultados << gastos_variables

    gastos_fijos = Tree::TreeNode.new("Gastos fijos")
    gastos_fijos << Tree::TreeNode.new("ABL")
    gastos_fijos << Tree::TreeNode.new("Expensas")
    gastos_fijos << Tree::TreeNode.new("Luz")
    gastos_fijos << Tree::TreeNode.new("Internet")
    gastos_fijos << Tree::TreeNode.new("Alquiler")
    gastos_fijos << Tree::TreeNode.new("Sueldos")
    gastos_fijos << Tree::TreeNode.new("Aguinaldos")
    gastos_fijos << Tree::TreeNode.new("Vacaciones")
    gastos_fijos << Tree::TreeNode.new("Tarjeta de credito")
    gastos_fijos << Tree::TreeNode.new("Mantenimiento sistema")
    gastos_fijos << Tree::TreeNode.new("Alojamiento servidor")
    gastos_fijos << Tree::TreeNode.new("Contador")
    gastos_fijos << Tree::TreeNode.new("Impuesto cartel")
    cargas_sociales = Tree::TreeNode.new("Cargas sociales")
    cargas_sociales << Tree::TreeNode.new("INACAP")
    cargas_sociales << Tree::TreeNode.new("FECyS")
    cargas_sociales << Tree::TreeNode.new("Seguro la estrella")
    cargas_sociales << Tree::TreeNode.new("Sindicato de comercio")
    gastos_fijos << cargas_sociales
    gastos_fijos << Tree::TreeNode.new("Monotributo")
    resultados << gastos_fijos

    otros_gastos = Tree::TreeNode.new("Otros gastos")
    otros_gastos << Tree::TreeNode.new("Viaticos")
    resultados << otros_gastos

    resultados << Tree::TreeNode.new("Resultado por tenencia")
    resultados << Tree::TreeNode.new("Recaudacion")
    @accounts << resultados
  end


  def test_shoud_save_yaml
    File.open( '../accounts.yml','w') { |file| file.puts @accounts.to_yaml }
  end

  def test_shoud_load_yaml
    begin
      accounts = YAML::load( File.read( '../accounts.yml' ) )
    rescue => e
      accounts = Tree::TreeNode.new("Cuentas", "Plan de cuentas en blanco")
    end
    # accounts.print_tree
    assert accounts.size > 10
  end

end

