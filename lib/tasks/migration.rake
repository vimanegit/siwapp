namespace :siwapp do
  namespace :migrate do
    desc "Makes the migration of old siwapp (sf1) to new one."
    task :old_database do
      # Get db config from databases.yml for the current environment
      client = Mysql2::Client.new(**ActiveRecord::Base.connection_config)

      client.query("ALTER TABLE common DROP FOREIGN KEY common_recurring_invoice_id_common_id")
      client.query("ALTER TABLE common DROP FOREIGN KEY common_customer_id_customer_id")
      client.query("ALTER TABLE common DROP FOREIGN KEY common_series_id_series_id")
      client.query("ALTER TABLE item DROP FOREIGN KEY item_common_id_common_id")
      client.query("ALTER TABLE item DROP FOREIGN KEY item_product_id_product_id")
      client.query("ALTER TABLE item_tax DROP FOREIGN KEY item_tax_item_id_item_id")
      client.query("ALTER TABLE payment DROP FOREIGN KEY payment_invoice_id_common_id")
      client.query("ALTER TABLE sf_guard_group_permission DROP FOREIGN KEY sf_guard_group_permission_group_id_sf_guard_group_id")
      client.query("ALTER TABLE sf_guard_group_permission DROP FOREIGN KEY sf_guard_group_permission_permission_id_sf_guard_permission_id")
      client.query("ALTER TABLE sf_guard_remember_key DROP FOREIGN KEY sf_guard_remember_key_user_id_sf_guard_user_id")
      client.query("ALTER TABLE sf_guard_user_group DROP FOREIGN KEY sf_guard_user_group_group_id_sf_guard_group_id")
      client.query("ALTER TABLE sf_guard_user_group DROP FOREIGN KEY sf_guard_user_group_user_id_sf_guard_user_id")
      client.query("ALTER TABLE sf_guard_user_permission DROP FOREIGN KEY sf_guard_user_permission_permission_id_sf_guard_permission_id")
      client.query("ALTER TABLE sf_guard_user_permission DROP FOREIGN KEY sf_guard_user_permission_user_id_sf_guard_user_id")
      client.query("ALTER TABLE sf_guard_user_profile DROP FOREIGN KEY sf_guard_user_profile_sf_guard_user_id_sf_guard_user_id")

      client.query("DROP TABLE sf_guard_group")
      client.query("DROP TABLE sf_guard_group_permission")
      client.query("DROP TABLE sf_guard_permission")
      client.query("DROP TABLE sf_guard_remember_key")
      client.query("DROP TABLE sf_guard_user")
      client.query("DROP TABLE sf_guard_user_group")
      client.query("DROP TABLE sf_guard_user_permission")
      client.query("DROP TABLE sf_guard_user_profile")
      client.query("DROP TABLE migration_version")

      client.query("ALTER TABLE common CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE common CHANGE recurring_invoice_id recurring_invoice_id INT")
      client.query("ALTER TABLE common CHANGE series_id serie_id INT")
      client.query("ALTER TABLE common CHANGE customer_id customer_id INT")
      client.query("ALTER TABLE common CHANGE invoicing_address invoicing_address TEXT")
      client.query("ALTER TABLE common CHANGE shipping_address shipping_address TEXT")
      client.query("ALTER TABLE common CHANGE terms terms TEXT")
      client.query("ALTER TABLE common CHANGE notes notes TEXT")
      client.query("ALTER TABLE common CHANGE base_amount base_amount DECIMAL(53, 15) DEFAULT 0")
      client.query("ALTER TABLE common CHANGE discount_amount discount_amount DECIMAL(53, 15) DEFAULT 0")
      client.query("ALTER TABLE common CHANGE net_amount net_amount DECIMAL(53, 15) DEFAULT 0")
      client.query("ALTER TABLE common CHANGE gross_amount gross_amount DECIMAL(53, 15) DEFAULT 0")
      client.query("ALTER TABLE common CHANGE paid_amount paid_amount DECIMAL(53, 15) DEFAULT 0")
      client.query("ALTER TABLE common CHANGE tax_amount tax_amount DECIMAL(53, 15) DEFAULT 0")

      client.query("ALTER TABLE customer CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE customer CHANGE invoicing_address invoicing_address TEXT")
      client.query("ALTER TABLE customer CHANGE shipping_address shipping_address TEXT")

      client.query("ALTER TABLE item CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE item CHANGE common_id common_id INT")
      client.query("ALTER TABLE item CHANGE product_id product_id INT")

      client.query("ALTER TABLE item_tax CHANGE item_id item_id INT")
      client.query("ALTER TABLE item_tax CHANGE tax_id tax_id INT")

      client.query("ALTER TABLE payment CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE payment CHANGE invoice_id invoice_id INT")
      client.query("ALTER TABLE payment CHANGE notes notes TEXT")

      client.query("ALTER TABLE product CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE product CHANGE description description TEXT")

      client.query("ALTER TABLE property CHANGE value value TEXT")

      client.query("ALTER TABLE series CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE series CHANGE first_number next_number INT")

      # Get max invoice number for each series and set the series next_number
      # field accordingly.
      series_info = client.query("SELECT `serie_id`, MAX(`number`) AS `current_number` FROM `common` WHERE `type` = 'Invoice' GROUP BY `serie_id`")
      series_info.each do |info|
        serie_id = info['serie_id']
        next_number = info['current_number'] + 1
        client.query("UPDATE `series` SET `next_number` = #{next_number} WHERE `id` = #{serie_id};")
      end

      # Tags

      client.query("ALTER TABLE `tag` CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE `tag` CHANGE `name` `name` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin NULL DEFAULT NULL")
      client.query("ALTER TABLE `tag` DROP `is_triple`")
      client.query("ALTER TABLE `tag` DROP `triple_namespace`")
      client.query("ALTER TABLE `tag` DROP `triple_key`")
      client.query("ALTER TABLE `tag` DROP `triple_value`")
      client.query("ALTER TABLE `tag` ADD `taggings_count` INT(11)  NULL  DEFAULT '0'  AFTER `name`")
      client.query("ALTER TABLE `tag` DROP INDEX `name_idx`")
      client.query("ALTER TABLE `tag` ADD UNIQUE INDEX `index_tags_on_name` (`name`)")
      client.query("RENAME TABLE `tag` TO `tags`")

      # Taggings

      client.query("ALTER TABLE `tagging` CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE `tagging` CHANGE `tag_id` `tag_id` INT")
      client.query("ALTER TABLE `tagging` CHANGE `taggable_id` `taggable_id` INT")
      client.query("ALTER TABLE `tagging` CHANGE `taggable_model` `taggable_type` VARCHAR(255)  CHARACTER SET utf8  COLLATE utf8_unicode_ci  NULL  DEFAULT NULL")
      client.query("ALTER TABLE `tagging` ADD `tagger_id` INT(11)  NULL  DEFAULT NULL  AFTER `taggable_id`")
      client.query("ALTER TABLE `tagging` ADD `tagger_type` VARCHAR(255)  CHARACTER SET utf8  COLLATE utf8_unicode_ci  NULL  DEFAULT NULL")
      client.query("ALTER TABLE `tagging` ADD `context` VARCHAR(128)  NULL  DEFAULT NULL  AFTER `tagger_type`")
      client.query("ALTER TABLE `tagging` ADD `created_at` DATETIME  NULL  AFTER `context`")
      client.query("ALTER TABLE `tagging` DROP INDEX `tag_idx`")
      client.query("ALTER TABLE `tagging` DROP INDEX `taggable_idx`")
      client.query("ALTER TABLE `tagging` ADD UNIQUE INDEX `taggings_idx` (`tag_id`, `taggable_id`, `taggable_type`, `context`, `tagger_id`, `tagger_type`)")
      client.query("ALTER TABLE `tagging` ADD INDEX `index_taggings_on_taggable_id_and_taggable_type_and_context` (`taggable_id`, `taggable_type`, `context`)")
      client.query("RENAME TABLE `tagging` TO `taggings`")

      client.query("UPDATE `taggings` SET `taggable_type` = 'Common', `context` = 'tags', `created_at` = '" << DateTime.now.strftime('%Y/%m/%d %H:%M:%S') << "'")

      # Update taggings_count

      tags = client.query("SELECT `tag_id` AS `id`, COUNT(`tag_id`) AS `taggings_count` FROM `taggings` GROUP BY `tag_id`")
      tags.each do |tag|
         id = tag['id']
         taggings_count = tag['taggings_count']
         client.query("UPDATE `tags` SET `taggings_count` = #{taggings_count} WHERE `id` = #{id}")
      end

      # Taxes

      client.query("ALTER TABLE tax CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")

      # Templates

      client.query("ALTER TABLE template CHANGE `id` `id` INT NOT NULL AUTO_INCREMENT")
      client.query("ALTER TABLE template CHANGE template template TEXT")

      # Table renaming according to rails convention
      client.query("RENAME TABLE common TO commons")
      client.query("RENAME TABLE customer TO customers")
      client.query("RENAME TABLE item TO items")
      client.query("RENAME TABLE payment TO payments")
      client.query("RENAME TABLE product TO products")
      client.query("RENAME TABLE property TO properties")
      client.query("RENAME TABLE template TO templates")
      client.query("RENAME TABLE tax TO taxes")
      client.query("RENAME TABLE item_tax TO items_taxes")

      # Create migrations table
      client.query("CREATE TABLE `schema_migrations` (
         `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
         UNIQUE KEY `unique_schema_migrations` (`version`)
         ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci")

      # Get all migrations defined in the migrations directory
      migrations = Dir.glob(File.expand_path('../../../db/migrate', __FILE__) + '/*.rb')
      # Collect migration versions
      timestamps = migrations.collect{ |f| f.split("/").last.split("_").first }
      # And insert them into the schema_migrations table
      timestamps.each do |version|
        client.query("INSERT INTO `schema_migrations` (`version`) VALUES (#{version})")
      end
    end
  end
end
