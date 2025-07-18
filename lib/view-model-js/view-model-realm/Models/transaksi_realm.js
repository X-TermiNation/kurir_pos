//item dalam cart
const ItemsTransSchema = {
  name: "ItemTrans",
  embedded: true,
  properties: {
    _id: "objectId",
    id_reference: "string",
    nama_barang: "string",
    id_satuan: "string",
    satuan_price: "double", //harga satuan
    trans_qty: "int", //jumlah dalam cart per item
    persentase_diskon: { type: "int", optional: true },
    total_price: "double",
  },
};

const TransaksiSchema = {
  name: "Transaksi",
  properties: {
    _id: "objectId",
    id_cabang: "string",
    Items: { type: "list", objectType: "ItemTrans" }, //kumpulan item dalam cart yang dibeli
    trans_date: "date",
    payment_method: "string",
    delivery: "bool", //jika true akan membuat tabel delivery
    desc: { type: "string", optional: true },
    status: "string", //Pending,Confirmed
    grand_total: "double",
  },
  primaryKey: "_id",
};

const DeliverySchema = {
  name: "Delivery",
  properties: {
    _id: "objectId",
    id_cabang: "string",
    status: "string", //status pengiriman (Delivered/In Progress)
    alamat_tujuan: "string",
    no_telp_cust: "string",
    transaksi_id: "string",
    deliver_time: { type: "date", optional: true },
    bukti_pengiriman: { type: "string", optional: true },
  },
  primaryKey: "_id",
};

module.exports = { TransaksiSchema, ItemsTransSchema, DeliverySchema };
