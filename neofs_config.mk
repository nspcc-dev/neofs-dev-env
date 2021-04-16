# Update epoch duration in side chain blocks (make update.epoch_duration val=30)
update.epoch_duration:
	@./bin/config.sh EpochDuration $(val)

# Update max object size in bytes (make update.max_object_size val=1000)
update.max_object_size:
	@./bin/config.sh MaxObjectSize $(val)

# Update audit fee per result in fixed 12 (make update.audit_fee val=100)
update.audit_fee:
	@./bin/config.sh AuditFee $(val)

# Update container fee per alphabet node in fixed 12 (make update.container_fee val=500)
update.container_fee:
	@./bin/config.sh ContainerFee $(val)

# Update amount of EigenTrust iterations (make update.eigen_trust_iterations val=2)
update.eigen_trust_iterations:
	@./bin/config.sh EigenTrustIterations $(val)

# Update basic income rate in fixed 12 (make update.basic_income_rate val=1000)
update.basic_income_rate:
	@./bin/config.sh BasicIncomeRate $(val)
