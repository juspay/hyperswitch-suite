# Example: Using classified_metric_alarms for Multi-Threshold Alarms
#
# This example shows how to use the new classified_metric_alarms variable
# to drastically reduce alarm configuration while maintaining multi-severity support.
#
# COMPARISON:
# OLD WAY: 3 separate alarm definitions for RDS CPU (80 lines)
# NEW WAY: 1 alarm definition with 3 thresholds (25 lines)

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # =============================================================================
  # CLASSIFIED METRIC ALARMS - Multi-Threshold Support
  # =============================================================================
  # Each alarm can have multiple severity levels with different thresholds
  # The module automatically creates separate alarms for each threshold

  classified_metric_alarms = {

    # -------------------------------------------------------------------------
    # RDS Alerts - CPU Utilization with 3 severity levels
    # -------------------------------------------------------------------------
    rds-cpu = {
      classification = "rds-alerts"
      metric_name    = "CPUUtilization"
      namespace      = "AWS/RDS"
      dimensions = {
        DBClusterIdentifier = dependency.database.outputs.cluster_identifier
      }
      period    = 60
      statistic = "Average"

      # Define thresholds for each severity
      thresholds = {
        warning   = { threshold = 60, evaluation_periods = 5, treat_missing_data = "notBreaching" }
        high      = { threshold = 70, evaluation_periods = 5, treat_missing_data = "notBreaching" }
        critical  = { threshold = 80, evaluation_periods = 5, treat_missing_data = "breaching" }
      }

      # Map each threshold to severity configuration
      severity_config = {
        warning = {
          severity         = "sev3"
          description      = "SEV3: RDS CPU is above 60%. Monitor closely for scaling needs."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev3"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev3"]]
        }
        high = {
          severity         = "sev2"
          description      = "SEV2: RDS CPU is above 70%. Consider scaling or query optimization."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev2"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev2"]]
        }
        critical = {
          severity            = "sev1"
          description         = "SEV1: RDS CPU is above 80%. Immediate action required."
          alarm_actions       = [dependency.sns.outputs.topic_arns["sev1"]]
          ok_actions          = [dependency.sns.outputs.topic_arns["sev1"]]
          comparison_operator = "GreaterThanThreshold"
        }
      }
    }

    # -------------------------------------------------------------------------
    # RDS Alerts - Database Connections
    # -------------------------------------------------------------------------
    rds-connections = {
      classification = "rds-alerts"
      metric_name    = "DatabaseConnections"
      namespace      = "AWS/RDS"
      dimensions = {
        DBClusterIdentifier = dependency.database.outputs.cluster_identifier
      }
      period    = 60
      statistic = "Average"

      thresholds = {
        warning  = { threshold = 150, evaluation_periods = 3, treat_missing_data = "notBreaching" }
        critical = { threshold = 190, evaluation_periods = 3, treat_missing_data = "notBreaching" }
      }

      severity_config = {
        warning = {
          severity         = "sev3"
          description      = "SEV3: RDS has > 150 connections. Consider connection pooling."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev3"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev3"]]
        }
        critical = {
          severity         = "sev2"
          description      = "SEV2: RDS has > 190 connections (near limit). Scale immediately."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev2"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev2"]]
        }
      }
    }

    # -------------------------------------------------------------------------
    # RDS Alerts - Storage (Low threshold = LessThan)
    # -------------------------------------------------------------------------
    rds-storage = {
      classification = "rds-alerts"
      metric_name    = "FreeLocalStorage"
      namespace      = "AWS/RDS"
      dimensions = {
        DBClusterIdentifier = dependency.database.outputs.cluster_identifier
      }
      period    = 60
      statistic = "Average"

      thresholds = {
        critical = { threshold = 10737418240, evaluation_periods = 3, treat_missing_data = "breaching" }  # 10GB
      }

      severity_config = {
        critical = {
          severity            = "sev1"
          description         = "SEV1: RDS storage below 10GB. Immediate action required to prevent outage."
          alarm_actions       = [dependency.sns.outputs.topic_arns["sev1"]]
          ok_actions          = [dependency.sns.outputs.topic_arns["sev1"]]
          comparison_operator = "LessThanThreshold"
        }
      }
    }

    # -------------------------------------------------------------------------
    # ElastiCache Alerts - CPU with 3 severity levels
    # -------------------------------------------------------------------------
    elasticache-cpu = {
      classification = "cache-alerts"
      metric_name    = "CPUUtilization"
      namespace      = "AWS/ElastiCache"
      dimensions = {
        CacheClusterId = dependency.elasticache.outputs.replication_group_id
      }
      period    = 300
      statistic = "Maximum"

      thresholds = {
        sev3 = { threshold = 60, evaluation_periods = 5, treat_missing_data = "notBreaching" }
        sev2 = { threshold = 70, evaluation_periods = 5, treat_missing_data = "notBreaching" }
        sev1 = { threshold = 80, evaluation_periods = 5, treat_missing_data = "breaching" }
      }

      severity_config = {
        sev3 = {
          severity         = "sev3"
          description      = "SEV3: ElastiCache CPU above 60% for 25 min. Monitor capacity."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev3"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev3"]]
        }
        sev2 = {
          severity         = "sev2"
          description      = "SEV2: ElastiCache CPU above 70% for 25 min. Consider scaling."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev2"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev2"]]
        }
        sev1 = {
          severity         = "sev1"
          description      = "SEV1: ElastiCache CPU above 80% for 25 min. Immediate action required."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev1"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev1"]]
        }
      }
    }

    # -------------------------------------------------------------------------
    # ElastiCache Alerts - Memory
    # -------------------------------------------------------------------------
    elasticache-memory = {
      classification = "cache-alerts"
      metric_name    = "DatabaseMemoryUsagePercentage"
      namespace      = "AWS/ElastiCache"
      dimensions = {
        CacheClusterId = dependency.elasticache.outputs.replication_group_id
      }
      period    = 60
      statistic = "Average"

      thresholds = {
        high = { threshold = 85, evaluation_periods = 3, treat_missing_data = "notBreaching" }
      }

      severity_config = {
        high = {
          severity         = "sev2"
          description      = "SEV2: ElastiCache memory above 85%. Consider scaling or TTL policies."
          alarm_actions    = [dependency.sns.outputs.topic_arns["sev2"]]
          ok_actions       = [dependency.sns.outputs.topic_arns["sev2"]]
        }
      }
    }

  }

  # =============================================================================
  # OUTPUTS
  # =============================================================================
  # classified_alarm_arns       - All classified alarm ARNs
  # classified_alarm_names      - All classified alarm names  
  # alarms_by_classification    - Grouped by classification (rds-alerts, cache-alerts, etc.)
  #
  # Example:
  # alarms_by_classification = {
  #   "rds-alerts"    = ["rds-cpu-warning", "rds-cpu-high", "rds-cpu-critical", ...]
  #   "cache-alerts"  = ["elasticache-cpu-sev3", "elasticache-cpu-sev2", ...]
  # }

}
