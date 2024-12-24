#include "dpdk_wrapper.h"

int wrte_errno() {
  return rte_errno;
}

uint16_t wrte_eth_rx_burst(uint16_t const port_id, uint16_t const queue_id, struct rte_mbuf **rx_pkts, uint16_t const nb_pkts) {
  return rte_eth_rx_burst(port_id, queue_id, rx_pkts, nb_pkts);
}

uint16_t wrte_eth_tx_burst(uint16_t const port_id, uint16_t const queue_id, struct rte_mbuf **tx_pkts, uint16_t const nb_pkts) {
  return rte_eth_tx_burst(port_id, queue_id, tx_pkts, nb_pkts);
}

int wrte_pktmbuf_alloc_bulk(struct rte_mempool *pool, struct rte_mbuf **mbufs, unsigned count) {
  return rte_pktmbuf_alloc_bulk(pool, mbufs, count);
}

struct rte_mbuf *wrte_pktmbuf_alloc(struct rte_mempool *mp) {
  return rte_pktmbuf_alloc(mp);
}

void wrte_pktmbuf_free(struct rte_mbuf *m) {
  return rte_pktmbuf_free(m);
}

void *wrte_pktmbuf_read(const struct rte_mbuf *m, uint32_t off, uint32_t len, void *buf) {
  return rte_pktmbuf_read(m, off, len, buf);
}
