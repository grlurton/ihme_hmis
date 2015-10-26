-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema hmis
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema hmis
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `hmis` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `hmis` ;

-- -----------------------------------------------------
-- Table `hmis`.`source`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`source` (
  `source_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `source_name` VARCHAR(45) NOT NULL COMMENT '',
  `source_date` DATETIME NOT NULL COMMENT '',
  PRIMARY KEY (`source_ID`)  COMMENT '',
  UNIQUE INDEX `source_ID_UNIQUE` (`source_ID` ASC)  COMMENT '')
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`country`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`country` (
  `country_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `country_name` VARCHAR(45) NOT NULL COMMENT '',
  PRIMARY KEY (`country_ID`)  COMMENT '',
  UNIQUE INDEX `idcountry_UNIQUE` (`country_ID` ASC)  COMMENT '')
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`organization_units`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`organization_units` (
  `organization_unit_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `organization_unit_name` VARCHAR(45) NOT NULL COMMENT '',
  `organization_unit_start` VARCHAR(45) NULL COMMENT '',
  `organization_unit_end` VARCHAR(45) NULL COMMENT '',
  `country_ID` INT NOT NULL COMMENT '',
  `group_pivot_ID` VARCHAR(45) NULL COMMENT '',
  PRIMARY KEY (`organization_unit_ID`)  COMMENT '',
  UNIQUE INDEX `idorganization_units_UNIQUE` (`organization_unit_ID` ASC)  COMMENT '',
  INDEX `organization_unit_to_country_idx` (`country_ID` ASC)  COMMENT '',
  CONSTRAINT `organization_unit_to_country`
    FOREIGN KEY (`country_ID`)
    REFERENCES `hmis`.`country` (`country_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`data_elements`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`data_elements` (
  `data_element_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `data_element_name` VARCHAR(45) NOT NULL COMMENT '',
  `metadata_pivot_ID` INT NULL COMMENT '',
  `country_ID` INT NOT NULL COMMENT '',
  PRIMARY KEY (`data_element_ID`)  COMMENT '',
  UNIQUE INDEX `data_elements_ID_UNIQUE` (`data_element_ID` ASC)  COMMENT '',
  INDEX `data_element_to_country_idx` (`country_ID` ASC)  COMMENT '',
  CONSTRAINT `data_element_to_country`
    FOREIGN KEY (`country_ID`)
    REFERENCES `hmis`.`country` (`country_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`category`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`category` (
  `category_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `category_name` VARCHAR(45) NOT NULL COMMENT '',
  `country_ID` INT NOT NULL COMMENT '',
  PRIMARY KEY (`category_ID`)  COMMENT '',
  UNIQUE INDEX `category_ID_UNIQUE` (`category_ID` ASC)  COMMENT '',
  INDEX `country_to_category_idx` (`country_ID` ASC)  COMMENT '',
  CONSTRAINT `country_to_category`
    FOREIGN KEY (`country_ID`)
    REFERENCES `hmis`.`country` (`country_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`data_values`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `hmis`.`data_values` (
  `value_ID` INT NOT NULL AUTO_INCREMENT COMMENT '',
  `organization_unit_ID` INT NOT NULL COMMENT '',
  `data_element_ID` INT NOT NULL COMMENT '',
  `category_ID` INT NOT NULL COMMENT '',
  `period` VARCHAR(45) NOT NULL COMMENT '',
  `value` INT NOT NULL COMMENT '',
  `source_ID` INT NOT NULL COMMENT '',
  `NID` VARCHAR(45) NULL COMMENT '',
  PRIMARY KEY (`value_ID`)  COMMENT '',
  UNIQUE INDEX `value_ID_UNIQUE` (`value_ID` ASC)  COMMENT '',
  INDEX `source_to_value_idx` (`source_ID` ASC)  COMMENT '',
  INDEX `organization_ID_to_value_idx` (`organization_unit_ID` ASC)  COMMENT '',
  INDEX `data_elements_to_value_idx` (`data_element_ID` ASC)  COMMENT '',
  INDEX `category_to_value_idx` (`category_ID` ASC)  COMMENT '',
  CONSTRAINT `source_to_value`
    FOREIGN KEY (`source_ID`)
    REFERENCES `hmis`.`source` (`source_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `organization_ID_to_value`
    FOREIGN KEY (`organization_unit_ID`)
    REFERENCES `hmis`.`organization_units` (`organization_unit_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `data_elements_to_value`
    FOREIGN KEY (`data_element_ID`)
    REFERENCES `hmis`.`data_elements` (`data_element_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `category_to_value`
    FOREIGN KEY (`category_ID`)
    REFERENCES `hmis`.`category` (`category_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`metadata_pivot`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`metadata_pivot` (
-- )
-- ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`metadata`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`metadata` (
-- )
-- ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`groups_pivot`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`groups_pivot` (
-- )
-- ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`groups`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`groups` (
-- )
-- ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`age`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`age` (
-- )
-- ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `hmis`.`gender`
-- -----------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `hmis`.`gender` (
-- )
-- ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
