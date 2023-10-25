require "language/node"

class Verdaccio < Formula
  desc "Caching npm proxy and local mirror"
  homepage "https://verdaccio.org/"
  url "https://registry.npmjs.org/verdaccio/-/verdaccio-5.27.0.tgz"
  sha256 "31808128320b788136fe4301a87e89afed5d60c41f6a9db61d47a685b2945a49"
  license "MIT"

  depends_on "node"

  def install
    etc.install "conf/default.yaml" => "verdaccio.yaml"
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
    deuniversalize_machos
  end

  test do
    File.write(testpath/"test-verdaccio.yaml", <<~ENDYAML)
      storage: ./storage
      plugins: ./plugins
      web:
        title: Verdaccio
      auth:
        htpasswd:
          file: ./htpasswd
      uplinks:
        npmjs:
          url: https://registry.npmjs.org/
      packages:
        '@*/*':
          access: $all
          publish: $authenticated
          unpublish: $authenticated
          proxy: npmjs
        '**':
          access: $all
          publish: $authenticated
          unpublish: $authenticated
          proxy: npmjs
      server:
        keepAliveTimeout: 60
      middlewares:
        audit:
          enabled: true
      log: { type: stdout, format: pretty, level: http }
    ENDYAML

    run [opt_bin/"verdaccio", "--listen", "12345", "--config", testpath/"test-verdaccio.yaml"]
    assert_match "A lightweight private npm proxy registry", shell_output("npm info verdaccio --registry http://localhost:12345")
  end

  def caveats 
    <<~EOC
      Verdaccio listens by default on port 4873.

      This formula installs the Verdaccio config file in 
      ${etc}/verdaccio.yaml.
      
      The service knows to look for it there, but if you run
      Verdaccio standalone you must either copy that file to 
      $HOME/.local/verdaccio/cnfig.yaml or invoke it as 
      verdaccio --config ${etc}/verdaccio.yaml.
    EOC
  end

  service do
    run [opt_bin/"verdaccio", "--config", etc/"verdaccio.yaml"]
    keep_alive true
    environment_variables PATH: "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    log_path var/"verdaccio/verdaccio.log"
    error_log_path var/"verdaccio/error.log"
  end
end
