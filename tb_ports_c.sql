tb_ports_c | CREATE TABLE `tb_ports_c` (
  `port_id` int(10) NOT NULL AUTO_INCREMENT,
  `cmts_ip` varchar(35) NOT NULL,
  `index_p` varchar(35) NOT NULL,
  `interface_p` varchar(35) NOT NULL,
  `node` varchar(35) NOT NULL,
  `ports_mod` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`port_id`)
) ENGINE=InnoDB AUTO_INCREMENT=60767 DEFAULT CHARSET=utf8mb4 |
