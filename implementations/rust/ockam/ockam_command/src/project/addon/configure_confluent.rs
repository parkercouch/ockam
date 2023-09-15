use clap::builder::NonEmptyStringValueParser;
use clap::Args;
use colorful::Colorful;
use miette::IntoDiagnostic;

use ockam::Context;
use ockam_api::cloud::addon::{Addons, ConfluentConfig};

use crate::node::util::{delete_embedded_node, start_node_manager};
use crate::project::addon::{check_configuration_completion, get_project_id};
use crate::util::node_rpc;
use crate::{docs, fmt_ok, CommandGlobalOpts};

const LONG_ABOUT: &str = include_str!("./static/configure_confluent/long_about.txt");
const AFTER_LONG_HELP: &str = include_str!("./static/configure_confluent/after_long_help.txt");

/// Configure the Confluent Cloud addon for a project
#[derive(Clone, Debug, Args)]
#[command(
long_about = docs::about(LONG_ABOUT),
after_long_help = docs::after_help(AFTER_LONG_HELP),
)]
pub struct AddonConfigureConfluentSubcommand {
    /// Ockam project name
    #[arg(
        long = "project",
        id = "project",
        value_name = "PROJECT_NAME",
        default_value = "default",
        value_parser(NonEmptyStringValueParser::new())
    )]
    project_name: String,

    /// Confluent Cloud bootstrap server address
    #[arg(
        long,
        id = "bootstrap_server",
        value_name = "BOOTSTRAP_SERVER",
        value_parser(NonEmptyStringValueParser::new())
    )]
    bootstrap_server: String,
}

impl AddonConfigureConfluentSubcommand {
    pub fn run(self, opts: CommandGlobalOpts) {
        node_rpc(run_impl, (opts, self));
    }
}

async fn run_impl(
    ctx: Context,
    (opts, cmd): (CommandGlobalOpts, AddonConfigureConfluentSubcommand),
) -> miette::Result<()> {
    let AddonConfigureConfluentSubcommand {
        project_name,
        bootstrap_server,
    } = cmd;
    let project_id = get_project_id(&opts.state, project_name.as_str())?;
    let config = ConfluentConfig::new(bootstrap_server);

    let node_manager = start_node_manager(&ctx, &opts, None).await?;
    let controller = node_manager
        .make_controller_client()
        .await
        .into_diagnostic()?;

    let response = controller
        .configure_confluent_addon(&ctx, project_id.clone(), config)
        .await
        .into_diagnostic()?
        .success()
        .into_diagnostic()?;
    check_configuration_completion(
        &opts,
        &ctx,
        &node_manager,
        &controller,
        project_id,
        response.operation_id,
    )
    .await?;

    opts.terminal
        .write_line(&fmt_ok!("Confluent addon configured successfully"))?;

    delete_embedded_node(&opts, &node_manager.node_name()).await;
    Ok(())
}
