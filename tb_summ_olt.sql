 tb_summ_ont | CREATE TABLE `tb_summ_ont` (
  `olt_id` int(10) NOT NULL AUTO_INCREMENT,
  `olt_name` varchar(35) NOT NULL,
  `olt_ip` varchar(35) NOT NULL,
  `ont_total` varchar(35) NOT NULL,
  `ont_up` varchar(35) NOT NULL,
  `ont_down` varchar(35) NOT NULL,
  `olt_mod` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`olt_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 |
