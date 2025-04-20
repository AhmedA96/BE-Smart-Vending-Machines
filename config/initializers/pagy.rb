# frozen_string_literal: true

# Pagy initializer file
# See https://ddnexus.github.io/pagy/api/pagy#configuration

# Default variables
Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:page] = 1

# Enable backend methods
require 'pagy/extras/array'
require 'pagy/extras/metadata'
